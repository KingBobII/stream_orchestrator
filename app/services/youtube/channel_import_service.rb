module Youtube
  class ChannelImportService
    def initialize(connection_channel)
      @connection_channel = connection_channel
    end

    def call
      response = Youtube::Client.new(connection_channel).fetch_my_channels!
      items = response.fetch("items", [])

      items.each do |item|
        channel = YoutubeChannel.find_or_initialize_by(external_id: item["id"])

        channel.assign_attributes(
          name: item.dig("snippet", "title").presence || "Untitled channel",
          description: item.dig("snippet", "description"),
          published_at: item.dig("snippet", "publishedAt"),
          thumbnail_url: item.dig("snippet", "thumbnails", "high", "url") ||
                         item.dig("snippet", "thumbnails", "default", "url"),
          uploads_playlist_id: item.dig("contentDetails", "relatedPlaylists", "uploads"),
          subscriber_count: item.dig("statistics", "subscriberCount").to_i,
          owner_id: connection_channel.owner_id,
          status: "active",
          connected_at: Time.current,
          last_synced_at: Time.current,
          sync_error: nil
        )

        channel.save!
      end

      items.size
    end

    private

    attr_reader :connection_channel
  end
end
