class AddYoutubeOAuthFieldsAndFixTokenStorageToYoutubeChannels < ActiveRecord::Migration[7.1]
  def change
    change_column :youtube_channels, :oauth_access_token, :text
    change_column :youtube_channels, :oauth_refresh_token, :text

    add_column :youtube_channels, :oauth_scope, :string
    add_column :youtube_channels, :oauth_token_type, :string
  end
end
