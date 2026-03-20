module ScheduleImports
  class ProcessPdf
    def self.call(schedule_import)
      new(schedule_import).call
    end

    def initialize(schedule_import)
      @schedule_import = schedule_import
    end

    def call
      @schedule_import.update!(ai_status: "processing", ai_error: nil)

      # Replace this with your current parser service if the name differs.
      #
      # Expected return shape:
      # {
      #   raw_text: "...",
      #   parsed_streams: [...]
      # }
      parsed_result = ScheduleImports::PDFParser.call(
        pdf_bytes: @schedule_import.pdf.download
      )

      raw_text = parsed_result[:raw_text]
      parsed_streams = parsed_result[:parsed_streams] || []

      cleaned_streams = ScheduleImports::AiCleaner.call(parsed_streams)

      @schedule_import.update!(
        raw_text: raw_text,
        parsed_streams: parsed_streams,
        cleaned_streams: cleaned_streams,
        status: "parsed",
        ai_status: "completed",
        ai_processed_at: Time.current,
        ai_model: ENV.fetch("OPENAI_CLEANUP_MODEL", "gpt-4o-mini"),
        ai_error: nil
      )

      @schedule_import
    rescue StandardError => e
      @schedule_import.update!(
        status: "failed",
        ai_status: "failed",
        ai_error: e.message,
        ai_processed_at: Time.current
      )

      raise
    end
  end
end
