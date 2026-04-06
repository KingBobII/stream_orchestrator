# module ScheduleImports
#   class StreamCreator
#     def self.call(rows:, schedule_import:, youtube_channel:)
#       new(rows, schedule_import: schedule_import, youtube_channel: youtube_channel).call
#     end

#     def initialize(rows, schedule_import:, youtube_channel:)
#       @rows = Array(rows)
#       @schedule_import = schedule_import
#       @youtube_channel = youtube_channel
#     end

#     def call
#       created_streams = []

#       rows.each do |row|
#         attrs = row.to_h.deep_stringify_keys
#         title = attrs["title"].to_s.strip
#         next if title.blank?

#         venue_name = attrs["location"].presence || attrs["venue_name"].presence

#         stream = Stream.create!(
#           title: title,
#           description: attrs["description"].presence,
#           status: "scheduled",
#           visibility: attrs["visibility"].presence || "public",
#           scheduled_at: parse_datetime(attrs["scheduled_at"], attrs["date_text"], attrs["time_text"]),
#           youtube_channel: youtube_channel,
#           schedule_import: schedule_import,
#           sync_status: "ready",
#           venue_type: venue_name.present? ? "physical" : "virtual",
#           venue_name: venue_name
#         )

#         created_streams << stream
#       end

#       created_streams
#     end

#     private

#     attr_reader :rows, :schedule_import, :youtube_channel

#     def parse_datetime(value, date_text = nil, time_text = nil)
#       return Time.zone.parse(value.to_s) if value.present?

#       date_part = schedule_import.schedule_date.presence || date_text.presence
#       time_part = time_text.presence
#       return nil if date_part.blank? || time_part.blank?

#       time_part = time_part.to_s.split(" - ").first.strip
#       Time.zone.parse("#{date_part} #{time_part}")
#     rescue ArgumentError, TypeError
#       nil
#     end
#   end
# end
module ScheduleImports
  class StreamCreator
    def self.call(rows:, schedule_import:, youtube_channel:)
      new(rows, schedule_import: schedule_import, youtube_channel: youtube_channel).call
    end

    def initialize(rows, schedule_import:, youtube_channel:)
      @rows = Array(rows)
      @schedule_import = schedule_import
      @youtube_channel = youtube_channel
    end

    def call
      created_streams = []

      rows.each do |row|
        attrs = row.to_h.deep_stringify_keys
        title = attrs["title"].to_s.strip
        next if title.blank?

        venue_type = resolved_venue_type(attrs)
        venue_name = resolved_venue_name(attrs)

        Stream.transaction do
          if source_stream_required?(venue_type)
            source_stream = Stream.create!(
              title: source_stream_title(title),
              description: source_stream_description(attrs, venue_name),
              status: "scheduled",
              visibility: "unlisted",
              scheduled_at: parse_datetime(attrs["scheduled_at"], attrs["date_text"], attrs["time_text"]),
              youtube_channel: youtube_channel,
              schedule_import: schedule_import,
              sync_status: "ready",
              stream_kind: "source",
              venue_type: venue_type,
              venue_name: venue_name
            )

            created_streams << source_stream

            public_stream = Stream.create!(
              title: title,
              description: attrs["description"].presence,
              status: "scheduled",
              visibility: attrs["visibility"].presence || "public",
              scheduled_at: parse_datetime(attrs["scheduled_at"], attrs["date_text"], attrs["time_text"]),
              youtube_channel: youtube_channel,
              schedule_import: schedule_import,
              sync_status: "ready",
              stream_kind: "public",
              source_stream: source_stream,
              venue_type: venue_type,
              venue_name: venue_name
            )

            created_streams << public_stream
          else
            public_stream = Stream.create!(
              title: title,
              description: attrs["description"].presence,
              status: "scheduled",
              visibility: attrs["visibility"].presence || "public",
              scheduled_at: parse_datetime(attrs["scheduled_at"], attrs["date_text"], attrs["time_text"]),
              youtube_channel: youtube_channel,
              schedule_import: schedule_import,
              sync_status: "ready",
              stream_kind: "public",
              venue_type: venue_type,
              venue_name: venue_name
            )

            created_streams << public_stream
          end
        end
      end

      created_streams
    end

    private

    attr_reader :rows, :schedule_import, :youtube_channel

    def resolved_venue_type(attrs)
      value = attrs["venue_type"].to_s.strip.downcase
      return value if Stream::VENUE_TYPES.include?(value)

      infer_venue_type(attrs["location"], attrs["description"])
    end

    def resolved_venue_name(attrs)
      attrs["venue_name"].presence ||
        attrs["location"].presence ||
        attrs["description"].presence
    end

    def infer_venue_type(location, description = nil)
      text = [location, description].compact.join(" ").squish

      return "virtual" if text.match?(/\b(zoom|teams|google meet|webex|webinar|online|virtual)\b/i)
      return "hybrid" if text.match?(/\bhybrid\b/i)
      return "physical" if text.present?

      "virtual"
    end

    def source_stream_required?(venue_type)
      %w[physical hybrid].include?(venue_type)
    end

    def source_stream_title(title)
      "(source)#{title}".to_s[0, 240]
    end

    def source_stream_description(attrs, venue_name)
      venue_name.presence ||
        attrs["location"].presence ||
        attrs["description"].presence
    end

    def parse_datetime(value, date_text = nil, time_text = nil)
      return Time.zone.parse(value.to_s) if value.present?

      date_part = schedule_import&.schedule_date.presence || date_text.presence
      time_part = time_text.presence
      return nil if date_part.blank? || time_part.blank?

      time_part = time_part.to_s.split(" - ").first.strip
      Time.zone.parse("#{date_part} #{time_part}")
    rescue ArgumentError, TypeError
      nil
    end
  end
end
