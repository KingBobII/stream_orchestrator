# # app/services/schedule_imports/entry_parser.rb
# module ScheduleImports
#   class EntryParser
#     TIME_PATTERN = /\b(?<start>\d{1,2}:\d{2})(?:\s*[–-]\s*(?<end>\d{1,2}:\d{2}))?\b/

#     def initialize(raw_block)
#       @raw_block = raw_block.to_s
#     end

#     def call
#       text = normalize(@raw_block)

#       time_match = text.match(TIME_PATTERN)
#       return nil unless time_match

#       start_time = time_match[:start]
#       end_time = time_match[:end]

#       # Remove trailing "Live on..." junk
#       text = text.split(/Live on|Delayed broadcast/i).first.to_s.strip

#       # Extract structured parts
#       match = text.match(/\A
#         .*?
#         (?<title>.+?)\s*\((?<jurisdiction>[^)]+)\),\s*
#         \[(?<description>.+?)\],\s*
#         (?<location>.+?)
#         ,\s*\d{1,2}:\d{2}
#       /xm)

#       return nil unless match

#       {
#         title: match[:title].squish,
#         description: match[:description].squish,
#         location: match[:location].squish,
#         start_time: start_time,
#         end_time: end_time,
#         visibility: "public",
#         raw_text: @raw_block
#       }
#     end

#     private

#     def normalize(text)
#       text.to_s
#           .tr("\u00A0", " ")
#           .gsub(/[–—]/, "-")
#           .squish
#     end

#     def parse_body(body)
#       primary = /\A(?<title>.+?)\s*\((?<jurisdiction>[^)]+)\),\s*\[(?<description>.+?)\],\s*(?<location>.+)\z/
#       fallback = /\A(?<title>.+?)\s*,\s*\[(?<description>.+?)\],\s*(?<location>.+)\z/

#       match = body.match(primary) || body.match(fallback)
#       return nil unless match

#       {
#         title: match[:title].squish,
#         description: match[:description].squish,
#         location: match[:location].squish,
#         visibility: "public"
#       }
#     end
#   end
# end
