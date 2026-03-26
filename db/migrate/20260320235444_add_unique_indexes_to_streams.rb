class AddUniqueIndexesToStreams < ActiveRecord::Migration[7.1]
  def change
    add_index :streams, :youtube_broadcast_id, unique: true
    add_index :streams, :youtube_stream_id, unique: true
    add_index :streams, :youtube_video_id, unique: true
  end
end
