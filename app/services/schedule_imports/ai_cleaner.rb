# require "net/http"
# require "json"
# require "uri"

# module ScheduleImports
#   class AiCleaner
#     def self.call(parsed_streams)
#       new(parsed_streams).call
#     end

#     def initialize(parsed_streams)
#       @parsed_streams = Array(parsed_streams).map(&:deep_stringify_keys)
#       @api_key = ENV.fetch("OPENAI_API_KEY")
#       @model = ENV.fetch("OPENAI_CLEANUP_MODEL", "gpt-4o-mini")
#     end

#     def call
#       response_text = chat_completion
#       parsed = parse_json(response_text)

#       normalize_rows(parsed)
#     rescue StandardError => e
#       Rails.logger.error("[ScheduleImports::AiCleaner] #{e.class}: #{e.message}")
#       fallback_rows
#     end

#     private

#     def chat_completion
#       uri = URI("https://api.openai.com/v1/chat/completions")

#       request = Net::HTTP::Post.new(uri)
#       request["Authorization"] = "Bearer #{@api_key}"
#       request["Content-Type"] = "application/json"

#       request.body = {
#         model: @model,
#         temperature: 0.2,
#         messages: [
#           {
#             role: "system",
#             content: <<~SYSTEM
#               You clean schedule items extracted from PDFs.

#               Rules:
#               - Do not invent facts.
#               - Do not remove important scheduling information.
#               - Remove obvious boilerplate from titles when it is clearly administrative noise.
#               - Improve grammar and readability.
#               - Keep the meaning the same.
#               - If uncertain, leave a field blank rather than guessing.
#               - Return ONLY valid JSON.
#             SYSTEM
#           },
#           {
#             role: "user",
#             content: <<~USER
#               Clean these schedule rows.

#               Return JSON in this shape:
#               {
#                 "rows": [
#                   {
#                     "index": 1,
#                     "raw_title": "...",
#                     "title": "...",
#                     "raw_description": "...",
#                     "description": "...",
#                     "committee": "...",
#                     "location": "...",
#                     "date_text": "...",
#                     "time_text": "...",
#                     "scheduled_at": "...",
#                     "visibility": "public",
#                     "notes": "..."
#                   }
#                 ]
#               }

#               Input rows:
#               #{JSON.pretty_generate(@parsed_streams)}
#             USER
#           }
#         ]
#       }.to_json

#       response = Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
#         http.request(request)
#       end

#       unless response.is_a?(Net::HTTPSuccess)
#         raise "OpenAI request failed: #{response.code} #{response.body}"
#       end

#       body = JSON.parse(response.body)
#       body.dig("choices", 0, "message", "content").to_s
#     end

#     def parse_json(text)
#       cleaned = text.strip

#       if cleaned.start_with?("```")
#         cleaned = cleaned.sub(/\A```(?:json)?\s*/i, "").sub(/\s*```\z/, "")
#       end

#       JSON.parse(cleaned)
#     end

#     def normalize_rows(parsed)
#       rows = parsed["rows"] || parsed[:rows] || []
#       rows.map do |row|
#         row = row.deep_stringify_keys

#         {
#           "index" => row["index"],
#           "raw_title" => row["raw_title"].presence,
#           "title" => row["title"].presence || row["raw_title"].presence,
#           "raw_description" => row["raw_description"].presence,
#           "description" => row["description"].presence || row["raw_description"].presence,
#           "committee" => row["committee"].presence,
#           "location" => row["location"].presence,
#           "date_text" => row["date_text"].presence,
#           "time_text" => row["time_text"].presence,
#           "scheduled_at" => row["scheduled_at"].presence,
#           "visibility" => row["visibility"].presence || "public",
#           "notes" => row["notes"].presence
#         }
#       end
#     end

#     def fallback_rows
#       @parsed_streams.each_with_index.map do |row, index|
#         {
#           "index" => index + 1,
#           "raw_title" => row["raw_title"].presence || row["title"].presence,
#           "title" => row["title"].presence || row["raw_title"].presence,
#           "raw_description" => row["raw_description"].presence || row["description"].presence,
#           "description" => row["description"].presence || row["raw_description"].presence,
#           "committee" => row["committee"].presence,
#           "location" => row["location"].presence,
#           "date_text" => row["date_text"].presence,
#           "time_text" => row["time_text"].presence,
#           "scheduled_at" => row["scheduled_at"].presence,
#           "visibility" => row["visibility"].presence || "public",
#           "notes" => "AI cleanup unavailable; using parser output."
#         }
#       end
#     end
#   end
# end
# app/services/schedule_imports/ai_cleaner.rb
require "net/http"
require "json"
require "uri"

module ScheduleImports
  class AiCleaner
    PARLIAMENT_MARKER_REGEX = /\((National Assembly|National Council of Provinces)\)/i

    def self.call(parsed_streams)
      new(parsed_streams).call
    end

    def initialize(parsed_streams)
      @parsed_streams = Array(parsed_streams).map(&:deep_stringify_keys)
      @api_key = ENV["OPENAI_API_KEY"]
      @model = ENV.fetch("OPENAI_CLEANUP_MODEL", "gpt-4o-mini")

      raise "OPENAI_API_KEY is missing" if @api_key.blank?
    end

    def call
      input_rows = preclean_rows(@parsed_streams)
      response_text = chat_completion(input_rows)
      parsed = parse_json(response_text)

      rows = normalize_rows(parsed)

      # Safety net: if AI removed the parliament marker from the description,
      # restore it from the raw title.
      rows.each_with_index do |row, index|
        raw_row = input_rows[index] || {}
        row["description"] = ensure_marker_in_description(
          raw_title: raw_row["raw_title"] || raw_row["title"],
          title: row["title"],
          description: row["description"]
        )
      end

      rows
    rescue StandardError => e
      Rails.logger.error("[ScheduleImports::AiCleaner] #{e.class}: #{e.message}")
      fallback_rows
    end

    private

    def preclean_rows(rows)
      rows.map do |row|
        row = row.deep_stringify_keys
        title = row["title"].to_s.strip
        description = row["description"].to_s.strip

        marker_match = title.match(PARLIAMENT_MARKER_REGEX)

        if marker_match
          split_index = marker_match.begin(0)
          marker_and_rest = title[split_index..].to_s.strip
          cleaned_title = title[0...split_index].strip

          {
            "title" => cleaned_title,
            "description" => [marker_and_rest, description].reject(&:blank?).join(" ").strip,
            "location" => row["location"],
            "start_time" => row["start_time"],
            "end_time" => row["end_time"],
            "visibility" => row["visibility"],
            "raw_title" => row["title"],
            "raw_description" => row["description"]
          }
        else
          row
        end
      end
    end

    def chat_completion(rows)
      uri = URI("https://api.openai.com/v1/chat/completions")

      request = Net::HTTP::Post.new(uri)
      request["Authorization"] = "Bearer #{@api_key}"
      request["Content-Type"] = "application/json"

      request.body = {
        model: @model,
        temperature: 0.2,
        messages: [
          {
            role: "system",
            content: <<~SYSTEM
              You clean schedule rows extracted from parliamentary PDF documents.

              Critical rules:
              - Do not invent facts.
              - Do not remove important schedule details.
              - Keep raw_title and raw_description unchanged in the output.
              - The title must be only the clean committee/activity name BEFORE the first occurrence of:
                "(National Assembly)" or "(National Council of Provinces)".
              - The description must include that marker EXACTLY AS WRITTEN if it appears in the title.
              - Never delete the marker from the description.
              - Never rewrite the marker into a different phrase.
              - If the title contains text after the marker, move that trailing text into the description.
              - If the title does not contain one of those markers, leave the title clean and do not force a marker.
              - Improve grammar and readability only.
              - If uncertain, leave a field blank rather than guessing.

              Return ONLY valid JSON in this exact shape:
              {
                "rows": [
                  {
                    "index": 1,
                    "raw_title": "...",
                    "title": "...",
                    "raw_description": "...",
                    "description": "...",
                    "committee": "...",
                    "location": "...",
                    "date_text": "...",
                    "time_text": "...",
                    "scheduled_at": "...",
                    "visibility": "public",
                    "notes": "..."
                  }
                ]
              }
            SYSTEM
          },
          {
            role: "user",
            content: <<~USER
              Clean these schedule rows.

              Examples:

              Input title:
              "Joint Standing Committee on Defence (National Assembly),"

              Output title:
              "Joint Standing Committee on Defence"

              Output description:
              "(National Assembly), Engagement with the Reserve Force Council on the development of the Reserve Force and its perceived future roles, Consideration of outstanding minutes."

              Input title:
              "Select Committee on Cooperative Governance and Public Administration (Traditional Affairs, Human Settlements, Water & Sanitation) (National Council of Provinces),"

              Output title:
              "Select Committee on Cooperative Governance and Public Administration"

              Output description:
              "(National Council of Provinces), Tabling of final mandates on Public Service Commission Bill and adoption of committee report on the object of the Public Service Commission Bill."

              Important:
              - The description must preserve the parliament body marker if it exists.
              - Do not drop the parentheses marker.
              - Do not summarize the description so much that the marker disappears.

              Input rows:
              #{JSON.pretty_generate(rows)}
            USER
          }
        ]
      }.to_json

      response = Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
        http.request(request)
      end

      unless response.is_a?(Net::HTTPSuccess)
        raise "OpenAI request failed: #{response.code} #{response.body}"
      end

      body = JSON.parse(response.body)
      body.dig("choices", 0, "message", "content").to_s
    end

    def parse_json(text)
      cleaned = text.strip

      if cleaned.start_with?("```")
        cleaned = cleaned.sub(/\A```(?:json)?\s*/i, "").sub(/\s*```\z/, "")
      end

      JSON.parse(cleaned)
    end

    def normalize_rows(parsed)
      rows = parsed["rows"] || parsed[:rows] || []

      rows.map do |row|
        row = row.deep_stringify_keys

        {
          "index" => row["index"],
          "raw_title" => row["raw_title"].presence,
          "title" => row["title"].presence || row["raw_title"].presence,
          "raw_description" => row["raw_description"].presence,
          "description" => row["description"].presence || row["raw_description"].presence,
          "committee" => row["committee"].presence,
          "location" => row["location"].presence,
          "date_text" => row["date_text"].presence,
          "time_text" => row["time_text"].presence,
          "scheduled_at" => row["scheduled_at"].presence,
          "visibility" => row["visibility"].presence || "public",
          "notes" => row["notes"].presence
        }
      end
    end

    def ensure_marker_in_description(raw_title:, title:, description:)
      raw_title = raw_title.to_s
      title = title.to_s
      description = description.to_s.strip

      marker_match = raw_title.match(PARLIAMENT_MARKER_REGEX)
      return description if marker_match.nil?

      marker = marker_match[0]

      # If the description already contains the marker, leave it alone.
      return description if description.match?(PARLIAMENT_MARKER_REGEX)

      trailing_text = ""

      # If the raw title contained the marker and there is text after it,
      # preserve it in the description too.
      after_marker = raw_title.split(marker, 2).last.to_s
      if after_marker.present?
        trailing_text = after_marker
          .sub(/\A,\s*/, "")
          .sub(/\A-\s*/, "")
          .strip
      end

      rebuilt = [marker, trailing_text, description].reject(&:blank?).join(", ")

      rebuilt.sub(/,\s*,/, ", ").strip
    end

    def fallback_rows
      @parsed_streams.each_with_index.map do |row, index|
        row = row.deep_stringify_keys

        {
          "index" => index + 1,
          "raw_title" => row["title"].presence,
          "title" => clean_title_from_raw(row["title"]),
          "raw_description" => row["description"].presence,
          "description" => ensure_marker_in_description(
            raw_title: row["title"],
            title: clean_title_from_raw(row["title"]),
            description: row["description"]
          ),
          "committee" => clean_title_from_raw(row["title"]),
          "location" => row["location"].presence,
          "date_text" => nil,
          "time_text" => [row["start_time"], row["end_time"]].compact.join(" - ").presence || row["start_time"],
          "scheduled_at" => nil,
          "visibility" => row["visibility"].presence || "public",
          "notes" => "AI cleanup unavailable; using parser output."
        }
      end
    end

    def clean_title_from_raw(raw_title)
      title = raw_title.to_s.strip
      marker_match = title.match(PARLIAMENT_MARKER_REGEX)

      return title if marker_match.nil?

      title[0...marker_match.begin(0)].to_s.strip.sub(/,\s*\z/, "")
    end
  end
end
