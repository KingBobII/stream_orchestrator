module Youtube
  class SyncStreamJob < ApplicationJob
    queue_as :default

    def perform(stream_id)
      stream = Stream.find(stream_id)
      Youtube::BroadcastCreator.new(stream).call
    end
  end
end
