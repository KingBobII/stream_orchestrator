# module Youtube
#   class BroadcastCreator
#     def initialize(stream, client: Youtube::Client.new)
#       @stream = stream
#       @client = client
#     end

#     def call
#       raise ArgumentError, "Stream is not ready for YouTube sync" unless stream.ready_for_youtube_sync?

#       stream.update!(sync_status: :syncing, sync_error: nil)

#       result = client.create_broadcast(stream)

#       stream.update!(
#         youtube_broadcast_id: result.broadcast_id,
#         youtube_url: result.url,
#         sync_status: :synced,
#         synced_at: Time.current,
#         sync_error: nil
#       )

#       result
#     rescue StandardError => e
#       stream.update!(
#         sync_status: :failed,
#         sync_error: e.message
#       )
#       raise
#     end

#     private

#     attr_reader :stream, :client
#   end
# end
module Youtube
  class BroadcastCreator
    def initialize(stream, client: Youtube::Client.new)
      @stream = stream
      @client = client
    end

    def call
      raise ArgumentError, "Stream is not ready for YouTube sync" unless stream.needs_scheduling_on_youtube?

      stream.update!(sync_status: :syncing, sync_error: nil)

      result = client.create_broadcast(stream)

      stream.update!(
        external_video_id: result.broadcast_id,
        sync_status: :synced,
        synced_at: Time.current,
        sync_error: nil
      )

      result
    rescue StandardError => e
      stream.update!(
        sync_status: :failed,
        sync_error: e.message
      )
      raise
    end

    private

    attr_reader :stream, :client
  end
end
