module Youtube
  class SyncChannelMetadataJob < ApplicationJob
    queue_as :default

    def perform(youtube_channel_id)
      youtube_channel = YoutubeChannel.find_by(id: youtube_channel_id)
      return unless youtube_channel

      Youtube::ChannelSyncService.new(youtube_channel).perform
    end
  end
end
