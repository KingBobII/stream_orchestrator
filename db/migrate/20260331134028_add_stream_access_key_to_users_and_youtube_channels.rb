class AddStreamAccessKeyToUsersAndYoutubeChannels < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :stream_access_key, :string
    add_index :users, :stream_access_key

    add_column :youtube_channels, :stream_access_key, :string
    add_index :youtube_channels, :stream_access_key
  end
end
