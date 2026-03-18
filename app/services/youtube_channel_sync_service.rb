class YoutubeChannelSyncService
  def initialize(youtube_channel)
    @youtube_channel = youtube_channel
  end

  def enqueue_metadata_sync
    # prefer background job:
    # YoutubeChannelMetadataJob.perform_later(@youtube_channel.id)
    perform_metadata_sync
  end

  def perform_metadata_sync
    Rails.logger.info("[YoutubeChannelSyncService] sync for #{@youtube_channel.id}")
    # TODO: implement:
    # 1) refresh access token using oauth_refresh_token
    # 2) call YouTube Data API channels.list(part: 'snippet,brandingSettings', id: external_id)
    # 3) update avatar_url, banner_url, name, description, published_at, etc.
    true
  rescue => e
    Rails.logger.error("[YoutubeChannelSyncService] failed: #{e.message}")
    false
  end
end
