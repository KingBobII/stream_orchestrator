module Youtube
  class BroadcastCreator
    Result = Struct.new(
      :broadcast_id,
      :stream_id,
      :video_id,
      :watch_url,
      :ingestion_address,
      :stream_name,
      :thumbnails,
      :status,
      :error,
      keyword_init: true
    )

    def initialize(stream, client: Youtube::Client.new(stream.youtube_channel))
      @stream = stream
      @client = client
    end

    def call
      raise ArgumentError, "Stream is not ready for YouTube sync" unless stream.syncable_to_youtube?
      raise ArgumentError, "Stream is already linked to YouTube" if stream.youtube_broadcast_id.present?

      stream.with_lock do
        stream.update!(sync_status: "syncing", sync_error: nil)

        broadcast_payload = client.create_broadcast(stream)
        stream_payload = client.create_stream(stream)

        client.bind_broadcast_to_stream(
          broadcast_id: broadcast_payload["id"],
          stream_id: stream_payload.stream_id
        )

        youtube_video_id = broadcast_payload["id"]
        youtube_watch_url = "https://www.youtube.com/watch?v=#{youtube_video_id}"

        stream.update!(
          youtube_broadcast_id: broadcast_payload["id"],
          youtube_stream_id: stream_payload.stream_id,
          youtube_video_id: youtube_video_id,
          youtube_watch_url: youtube_watch_url,
          youtube_ingestion_address: stream_payload.ingestion_address,
          youtube_stream_name: stream_payload.stream_name,
          sync_status: "synced",
          synced_at: Time.current,
          sync_error: nil
        )

        Result.new(
          broadcast_id: broadcast_payload["id"],
          stream_id: stream_payload.stream_id,
          video_id: youtube_video_id,
          watch_url: youtube_watch_url,
          ingestion_address: stream_payload.ingestion_address,
          stream_name: stream_payload.stream_name,
          thumbnails: stream.thumbnails,
          status: "synced",
          error: nil
        )
      end
    rescue StandardError => e
      stream.update!(sync_status: "failed", sync_error: e.message) if stream&.persisted?

      Result.new(
        broadcast_id: nil,
        stream_id: nil,
        video_id: nil,
        watch_url: nil,
        ingestion_address: nil,
        stream_name: nil,
        thumbnails: {},
        status: "failed",
        error: e.message
      )
    end

    private

    attr_reader :stream, :client
  end
end
