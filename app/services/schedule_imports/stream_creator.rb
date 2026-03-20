module ScheduleImports
  class StreamCreator
    def self.call(rows:)
      new(rows).call
    end

    def initialize(rows)
      @rows = Array(rows)
    end

    def call
      created_count = 0

      @rows.each do |row|
        attrs = row.to_h.deep_stringify_keys

        title = attrs["title"].to_s.strip
        next if title.blank?

        stream_attrs = {
          title: title,
          description: attrs["description"].presence,
          status: "scheduled",
          scheduled_at: parse_datetime(attrs["scheduled_at"]),
          visibility: attrs["visibility"].presence || "public"
        }

        stream_attrs.delete(:visibility) unless Stream.column_names.include?("visibility")
        stream_attrs.delete(:scheduled_at) if stream_attrs[:scheduled_at].blank? && !Stream.column_names.include?("scheduled_at")

        Stream.create!(stream_attrs)

        created_count += 1
      end

      created_count
    end

    private

    def parse_datetime(value)
      return nil if value.blank?

      Time.zone.parse(value.to_s)
    rescue ArgumentError, TypeError
      nil
    end
  end
end
