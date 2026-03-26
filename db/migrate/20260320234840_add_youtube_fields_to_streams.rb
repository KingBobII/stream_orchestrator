class AddYoutubeFieldsToStreams < ActiveRecord::Migration[7.1]
  def change
    add_column :streams, :youtube_broadcast_id, :string
    add_column :streams, :youtube_stream_id, :string
    add_column :streams, :youtube_video_id, :string
    add_column :streams, :youtube_watch_url, :string
  end
end
