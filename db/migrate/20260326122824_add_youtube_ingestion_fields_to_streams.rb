class AddYoutubeIngestionFieldsToStreams < ActiveRecord::Migration[7.1]
  def change
    add_column :streams, :youtube_ingestion_address, :string
    add_column :streams, :youtube_stream_name, :string
  end
end
