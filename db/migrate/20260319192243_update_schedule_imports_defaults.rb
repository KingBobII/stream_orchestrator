class UpdateScheduleImportsDefaults < ActiveRecord::Migration[7.1]
  def change
    change_column_default :schedule_imports, :status, from: nil, to: "pending"
    change_column_null :schedule_imports, :status, false

    change_column_default :schedule_imports, :parsed_streams, from: nil, to: []
    change_column_null :schedule_imports, :parsed_streams, false
  end
end
