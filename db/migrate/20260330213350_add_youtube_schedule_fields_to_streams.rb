class AddYoutubeScheduleFieldsToStreams < ActiveRecord::Migration[7.1]
  def change
    add_column :streams, :venue_type, :string, null: false, default: "virtual"
    add_column :streams, :venue_name, :string

    add_column :streams, :youtube_backup_ingestion_address, :text
    add_column :streams, :youtube_rtmps_ingestion_address, :text
    add_column :streams, :youtube_rtmps_backup_ingestion_address, :text

    add_column :streams, :youtube_synced_at, :datetime
  end
end
