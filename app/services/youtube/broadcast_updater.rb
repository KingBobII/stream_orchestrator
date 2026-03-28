module Youtube
  class BroadcastUpdater
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
      raise ArgumentError, "Stream is not linked to YouTube yet" if stream.youtube_broadcast_id.blank?
      raise ArgumentError, "Stream is not ready for YouTube sync" unless stream.syncable_to_youtube?

      stream.with_lock do
        stream.update!(sync_status: "syncing", sync_error: nil)

        client.update_broadcast(stream)

        stream.update!(
          sync_status: "synced",
          synced_at: Time.current,
          sync_error: nil
        )

        Result.new(
          broadcast_id: stream.youtube_broadcast_id,
          stream_id: stream.youtube_stream_id,
          video_id: stream.youtube_video_id,
          watch_url: stream.watch_url,
          ingestion_address: stream.youtube_ingestion_address,
          stream_name: stream.youtube_stream_name,
          thumbnails: stream.thumbnails,
          status: "synced",
          error: nil
        )
      end
    rescue StandardError => e
      stream.update!(sync_status: "failed", sync_error: e.message) if stream&.persisted?

      Result.new(
        broadcast_id: stream.youtube_broadcast_id,
        stream_id: stream.youtube_stream_id,
        video_id: stream.youtube_video_id,
        watch_url: stream.youtube_watch_url,
        ingestion_address: stream.youtube_ingestion_address,
        stream_name: stream.youtube_stream_name,
        thumbnails: stream.thumbnails,
        status: "failed",
        error: e.message
      )
    end

    private

    attr_reader :stream, :client
  end
end
