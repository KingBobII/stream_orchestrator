module Youtube
  class ChannelSyncService
    def initialize(youtube_channel)
      @youtube_channel = youtube_channel
    end

    def perform
      raise StandardError, "YouTube channel is not connected" unless youtube_channel.connected?

      response = Youtube::Client.new(youtube_channel).fetch_my_channel!
      item = response.fetch("items", []).first
      raise StandardError, "No YouTube channel returned for this account" if item.nil?

      youtube_channel.update!(
        external_id: item["id"],
        name: item.dig("snippet", "title").presence || youtube_channel.name,
        description: item.dig("snippet", "description"),
        thumbnail_url: item.dig("snippet", "thumbnails", "high", "url") ||
                       item.dig("snippet", "thumbnails", "default", "url"),
        uploads_playlist_id: item.dig("contentDetails", "relatedPlaylists", "uploads"),
        subscriber_count: item.dig("statistics", "subscriberCount").to_i,
        last_synced_at: Time.current,
        connected_at: youtube_channel.connected_at || Time.current,
        status: "active",
        sync_error: nil
      )

      Rails.logger.info("[Youtube::ChannelSyncService] sync for #{youtube_channel.id}")
      true
    rescue StandardError => e
      youtube_channel.update!(sync_error: e.message) if youtube_channel.persisted?
      Rails.logger.error("[Youtube::ChannelSyncService] failed: #{e.message}")
      false
    end

    private

    attr_reader :youtube_channel
  end
end
