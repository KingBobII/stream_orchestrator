class RenameExternalVideoIdInStreams < ActiveRecord::Migration[7.1]
  def change
    # Only remove the old column since the new one already exists
    remove_column :streams, :external_video_id, :string
  end
end
