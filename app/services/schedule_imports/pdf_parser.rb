# app/services/schedule_imports/pdf_parser.rb
require "pdf-reader"

module ScheduleImports
  class PdfParser
    TIME_LINE = /^\s*(\d{1,2}:\d{2})\s*[-–]?\s*(.*)\z/
    FULL_TIME_LINE = /^\s*(\d{1,2}:\d{2})\s*[-–]\s*(\d{1,2}:\d{2})\s*(.*)\z/i
    NOISE_INLINE = /Live on|Delayed broadcast on|YouTube|Iono\.fm|Parliament TV|●/i

    def initialize(io)
      @io = io
    end

    def call
      raw_text = extract_text
      lines = normalize_lines(raw_text)
      lines = merge_split_time_lines(lines)
      rows = build_rows(lines)
      parsed_streams = rows.filter_map { |row| parse_row(row) }

      Rails.logger.info("[ScheduleImports::PdfParser] rows=#{rows.size} parsed=#{parsed_streams.size}")
      Rails.logger.info("[ScheduleImports::PdfParser] first_row=#{rows.first.inspect}") if rows.first
      Rails.logger.info("[ScheduleImports::PdfParser] first_parsed=#{parsed_streams.first.inspect}") if parsed_streams.first

      {
        raw_text: raw_text,
        parsed_streams: parsed_streams
      }
    end

    private

    def extract_text
      @io.rewind if @io.respond_to?(:rewind)
      reader = PDF::Reader.new(@io)
      reader.pages.map(&:text).join("\n")
    end

    def normalize_lines(text)
      text
        .to_s
        .gsub(/\r\n?/, "\n")
        .gsub(/\u00A0/, " ")
        .gsub(/[–—]/, "-")
        .split("\n")
        .map { |line| clean_line(line) }
        .reject(&:blank?)
        .reject { |line| line.match?(/\A(TIME|ACTIVITY|FRIDAY\b|Page\s+\d+|Updated\b)/i) }
    end

    def clean_line(line)
      line
        .to_s
        .gsub(NOISE_INLINE, " ")
        .squeeze(" ")
        .strip
    end

    def merge_split_time_lines(lines)
      merged = []
      i = 0

      while i < lines.length
        current = lines[i]
        nxt = lines[i + 1]

        if current.match?(TIME_LINE) && nxt.present? && nxt.match?(TIME_LINE) && !current.include?("]")
          m1 = current.match(TIME_LINE)
          m2 = nxt.match(TIME_LINE)

          combined = "#{m1[1]} - #{m2[1]} #{m1[2]} #{m2[2]}".squish
          merged << combined
          i += 2
          next
        end

        merged << current
        i += 1
      end

      merged
    end

    def build_rows(lines)
      rows = []
      current = nil

      lines.each do |line|
        if line.match?(TIME_LINE)
          if current.present? && current.include?("]")
            rows << current.squish
            current = line.dup
          else
            current = [current, line].compact.join(" ")
          end
        else
          current = [current, line].compact.join(" ")
        end
      end

      rows << current.squish if current.present?
      rows.reject(&:blank?)
    end

    def parse_row(row)
      text = row.to_s.strip
      return nil unless text.match?(TIME_LINE)

      # Remove trailing repeated time at the end if present
      text = text.sub(/\s*,?\s*\d{1,2}:\d{2}\s*[-–]\s*\d{1,2}:\d{2}\s*\z/, "").squish

      time_match = text.match(/\A(?<start>\d{1,2}:\d{2})\s*-\s*(?<end>\d{1,2}:\d{2})\s+(?<rest>.+)\z/m)
      return nil unless time_match

      rest = time_match[:rest].squish

      # Split into:
      # prefix = title + optional jurisdiction
      # description = inside [ ... ]
      # location = everything after ], ...
      body_match = rest.match(/\A(?<prefix>.+?)\s*\[(?<description>.+?)\],\s*(?<location>.+)\z/m)
      return nil unless body_match

      prefix = body_match[:prefix].squish
      description = body_match[:description].squish
      location = body_match[:location].squish

      # Remove the final jurisdiction parenthetical only,
      # while keeping earlier parentheses that are part of the real title.
      title = prefix.sub(/\s*,\s*\([^)]*\)\s*\z/, "").squish

      {
        title: title,
        description: description,
        location: location,
        start_time: time_match[:start],
        end_time: time_match[:end],
        visibility: "public",
        raw_text: row
      }
    end
  end
end
