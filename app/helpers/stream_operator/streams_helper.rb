# module StreamOperator::StreamsHelper
#   def stream_start_time(stream)
#     [
#       stream.try(:scheduled_at),
#       stream.try(:scheduled_start_at),
#       stream.try(:start_time),
#       stream.try(:starts_at)
#     ].compact.first
#   end

#   def stream_end_time(stream)
#     [
#       stream.try(:scheduled_end_at),
#       stream.try(:end_time),
#       stream.try(:ends_at)
#     ].compact.first
#   end

#   def stream_key_value(stream)
#     stream.try(:stream_key) || stream.try(:key) || "Not set"
#   end

#   def stream_url_value(stream)
#     stream.try(:stream_url) || stream.try(:ingest_url) || stream.try(:rtmp_url) || "Not set"
#   end

#   def format_stream_datetime(value)
#     return "Not scheduled" if value.blank?

#     l(value, format: :long)
#   end
# end
# app/helpers/stream_operator/streams_helper.rb
module StreamOperator::StreamsHelper
  def stream_start_time(stream)
    [
      stream.try(:scheduled_at),
      stream.try(:scheduled_start_at),
      stream.try(:start_time),
      stream.try(:starts_at)
    ].compact.first
  end

  def stream_end_time(stream)
    [
      stream.try(:scheduled_end_at),
      stream.try(:end_time),
      stream.try(:ends_at)
    ].compact.first
  end

  def stream_key_value(stream)
    stream.try(:youtube_stream_name).presence ||
      stream.try(:youtube_stream_key).presence ||
      "Not set"
  end

  def stream_url_value(stream)
    stream.try(:youtube_ingestion_address).presence ||
      stream.try(:youtube_rtmp_url).presence ||
      "Not set"
  end

  def stream_watch_url_value(stream)
    stream.try(:watch_url).presence ||
      stream.try(:youtube_watch_url).presence ||
      "Not set"
  end

  def stream_venue_value(stream)
    stream.try(:venue_display_name).presence ||
      stream.try(:venue_name).presence ||
      "Virtual"
  end

  def format_stream_datetime(value)
    return "Not scheduled" if value.blank?

    l(value, format: :long)
  end
end
