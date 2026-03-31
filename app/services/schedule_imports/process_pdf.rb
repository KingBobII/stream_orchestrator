require "stringio"

module ScheduleImports
  class ProcessPdf
    def self.call(schedule_import)
      new(schedule_import).call
    end

    def initialize(schedule_import)
      @schedule_import = schedule_import
    end

    def call
      # 🚀 Step 1: start processing
      @schedule_import.update!(
        status: "processing",
        ai_status: "processing",
        ai_error: nil
      )

      parsed_result = ScheduleImports::PdfParser
        .new(StringIO.new(@schedule_import.pdf.download))
        .call

      raw_text = parsed_result[:raw_text]
      parsed_streams = parsed_result[:parsed_streams] || []

      # 🧠 Step 2: parsing done
      @schedule_import.update!(
        raw_text: raw_text,
        parsed_streams: parsed_streams,
        status: parsed_streams.any? ? "parsed" : "failed"
      )

      cleaned_streams = []

      begin
        # 🔑 Check API key BEFORE calling AI
        if ENV["OPENAI_API_KEY"].blank?
          raise "OPENAI_API_KEY is missing"
        end

        cleaned_streams = ScheduleImports::AiCleaner.call(parsed_streams)

        @schedule_import.update!(
          ai_status: cleaned_streams.any? ? "completed" : "failed",
          ai_model: ENV.fetch("OPENAI_CLEANUP_MODEL", "gpt-4o-mini"),
          ai_error: nil
        )

      rescue StandardError => e
        Rails.logger.error("[AI CLEANER ERROR] #{e.message}")

        # ⚠️ Fallback: use parsed streams instead
        cleaned_streams = parsed_streams

        @schedule_import.update!(
          ai_status: "failed",
          ai_error: e.message
        )
      end

      # 🧮 Always normalize scheduled_at (even fallback)
      cleaned_streams = normalize_rows_with_scheduled_at(cleaned_streams)

      # ✅ Step 3: finalize (ALWAYS complete pipeline)
      @schedule_import.update!(
        cleaned_streams: cleaned_streams,
        status: "completed",
        ai_processed_at: Time.current
      )

      @schedule_import

    rescue StandardError => e
      Rails.logger.error(e.full_message)

      @schedule_import.update!(
        status: "failed",
        ai_status: "failed",
        ai_error: e.message,
        ai_processed_at: Time.current
      )

      raise
    end

    private

    def normalize_rows_with_scheduled_at(rows)
      rows.map do |row|
        row = row.deep_stringify_keys

        row["scheduled_at"] ||= build_scheduled_at(row)

        row
      end
    end

    def build_scheduled_at(row)
      date_part = @schedule_import.schedule_date
      time_part = row["time_text"] || row["start_time"]

      return nil if date_part.blank? || time_part.blank?

      time_part = time_part.to_s.split(" - ").first.strip

      Time.zone.parse("#{date_part} #{time_part}")
    rescue ArgumentError, TypeError
      nil
    end
  end
end
