class AddAiCleanupFieldsToScheduleImports < ActiveRecord::Migration[7.1]
  def change
    add_column :schedule_imports, :cleaned_streams, :jsonb, null: false, default: []
    add_column :schedule_imports, :ai_status, :string, null: false, default: "pending"
    add_column :schedule_imports, :ai_model, :string
    add_column :schedule_imports, :ai_error, :text
    add_column :schedule_imports, :ai_processed_at, :datetime
  end
end
