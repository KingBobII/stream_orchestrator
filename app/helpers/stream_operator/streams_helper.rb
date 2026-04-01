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
    stream.try(:stream_key) || stream.try(:key) || "Not set"
  end

  def stream_url_value(stream)
    stream.try(:stream_url) || stream.try(:ingest_url) || stream.try(:rtmp_url) || "Not set"
  end

  def format_stream_datetime(value)
    return "Not scheduled" if value.blank?

    l(value, format: :long)
  end
end
