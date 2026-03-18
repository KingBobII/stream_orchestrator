class AddSyncTrackingToStreams < ActiveRecord::Migration[7.1]
  def change
    add_column :streams, :sync_status, :string, null: false, default: "pending"
    add_column :streams, :sync_error, :text
    add_column :streams, :synced_at, :datetime

    add_index :streams, :sync_status
    add_index :streams, :synced_at
  end
end
