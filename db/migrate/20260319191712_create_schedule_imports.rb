class CreateScheduleImports < ActiveRecord::Migration[7.1]
  def change
    create_table :schedule_imports do |t|
      t.string :status
      t.text :raw_text
      t.jsonb :parsed_streams
      t.date :schedule_date

      t.timestamps
    end
  end
end
