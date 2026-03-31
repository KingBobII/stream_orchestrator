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

        venue_name = attrs["location"].presence || attrs["venue_name"].presence

        stream = Stream.create!(
          title: title,
          description: attrs["description"].presence,
          status: "scheduled",
          visibility: attrs["visibility"].presence || "public",
          scheduled_at: parse_datetime(attrs["scheduled_at"], attrs["date_text"], attrs["time_text"]),
          youtube_channel: youtube_channel,
          schedule_import: schedule_import,
          sync_status: "ready",
          venue_type: venue_name.present? ? "physical" : "virtual",
          venue_name: venue_name
        )

        created_streams << stream
      end

      created_streams
    end

    private

    attr_reader :rows, :schedule_import, :youtube_channel

    def parse_datetime(value, date_text = nil, time_text = nil)
      return Time.zone.parse(value.to_s) if value.present?

      date_part = schedule_import.schedule_date.presence || date_text.presence
      time_part = time_text.presence
      return nil if date_part.blank? || time_part.blank?

      time_part = time_part.to_s.split(" - ").first.strip
      Time.zone.parse("#{date_part} #{time_part}")
    rescue ArgumentError, TypeError
      nil
    end
  end
end
