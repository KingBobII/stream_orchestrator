class AddScheduleImportToStreams < ActiveRecord::Migration[7.1]
  def change
    add_reference :streams, :schedule_import, foreign_key: true, null: true
  end
end
