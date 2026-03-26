module Youtube
  class SyncStreamJob < ApplicationJob
    queue_as :default

    def perform(stream_id)
      stream = Stream.find_by(id: stream_id)
      return unless stream
      return if stream.synced?
      return unless stream.ready_for_sync? || stream.failed_sync?

      Youtube::BroadcastCreator.new(stream).call
    end
  end
end
