module Youtube
  class ChannelSyncService
    def initialize(youtube_channel)
      @youtube_channel = youtube_channel
    end

    def perform
      Rails.logger.info("[Youtube::ChannelSyncService] sync for #{youtube_channel.id}")
      true
    rescue StandardError => e
      Rails.logger.error("[Youtube::ChannelSyncService] failed: #{e.message}")
      false
    end

    private

    attr_reader :youtube_channel
  end
end
