class ScheduleYoutubeBroadcastJob < ApplicationJob
  queue_as :default

  def perform(stream_id)
    stream = Stream.find_by(id: stream_id)
    return unless stream
    return unless stream.needs_scheduling_on_youtube?

    # Example service that creates the broadcast and returns external id and thumbnails
    result = YoutubeBroadcastService.new(stream).schedule!

    if result && result[:external_id].present?
      stream.update(
        external_video_id: result[:external_id],
        thumbnails: result[:thumbnails] || stream.thumbnails
      )
    end
  rescue StandardError => e
    Rails.logger.error("ScheduleYoutubeBroadcastJob failed for stream=#{stream_id}: #{e.message}")
    raise
  end
end
