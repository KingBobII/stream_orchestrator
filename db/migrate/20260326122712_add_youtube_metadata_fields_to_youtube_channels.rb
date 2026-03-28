class AddYoutubeMetadataFieldsToYoutubeChannels < ActiveRecord::Migration[7.1]
  def change
    add_column :youtube_channels, :thumbnail_url, :string
    add_column :youtube_channels, :uploads_playlist_id, :string
    add_column :youtube_channels, :subscriber_count, :integer, null: false, default: 0
    add_column :youtube_channels, :last_synced_at, :datetime
    add_column :youtube_channels, :connected_at, :datetime
    add_column :youtube_channels, :sync_error, :text
  end
end
