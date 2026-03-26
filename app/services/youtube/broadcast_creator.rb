# app/services/youtube/broadcast_creator.rb
module Youtube
  class BroadcastCreator
    Result = Struct.new(
      :broadcast_id,
      :stream_id,
      :video_id,
      :watch_url,
      :thumbnails,
      :status,
      :error,
      keyword_init: true
    )

    def initialize(stream, client: Youtube::Client.new)
      @stream = stream
      @client = client
    end

    def call
      raise ArgumentError, "Stream is not ready for YouTube sync" unless stream.ready_for_sync? || stream.failed_sync?

      stream.with_lock do
        return build_result_from_stream if stream.synced?

        stream.update!(sync_status: "syncing", sync_error: nil)

        broadcast_result = client.create_broadcast(stream)
        stream_result = client.create_stream(stream)

        client.bind_broadcast_to_stream(
          broadcast_id: broadcast_result.broadcast_id,
          stream_id: stream_result.stream_id
        )

        youtube_video_id = broadcast_result.video_id.presence || broadcast_result.broadcast_id
        youtube_watch_url = broadcast_result.watch_url.presence || "https://www.youtube.com/watch?v=#{youtube_video_id}"

        stream.update!(
          youtube_broadcast_id: broadcast_result.broadcast_id,
          youtube_stream_id: stream_result.stream_id,
          youtube_video_id: youtube_video_id,
          youtube_watch_url: youtube_watch_url,
          sync_status: "synced",
          synced_at: Time.current,
          sync_error: nil
        )

        Result.new(
          broadcast_id: broadcast_result.broadcast_id,
          stream_id: stream_result.stream_id,
          video_id: youtube_video_id,
          watch_url: youtube_watch_url,
          thumbnails: stream.thumbnails,
          status: "synced",
          error: nil
        )
      end
    rescue StandardError => e
      stream.update!(
        sync_status: "failed",
        sync_error: e.message
      ) if stream&.persisted?

      Result.new(
        broadcast_id: nil,
        stream_id: nil,
        video_id: nil,
        watch_url: nil,
        thumbnails: {},
        status: "failed",
        error: e.message
      )
    end

    private

    attr_reader :stream, :client

    def build_result_from_stream
      Result.new(
        broadcast_id: stream.youtube_broadcast_id,
        stream_id: stream.youtube_stream_id,
        video_id: stream.youtube_video_id,
        watch_url: stream.youtube_watch_url,
        thumbnails: stream.thumbnails,
        status: "synced",
        error: nil
      )
    end
  end
end
