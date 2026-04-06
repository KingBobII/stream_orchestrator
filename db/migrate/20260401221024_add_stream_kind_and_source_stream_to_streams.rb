class AddStreamKindAndSourceStreamToStreams < ActiveRecord::Migration[7.1]
  def change
    add_column :streams, :stream_kind, :string, null: false, default: "public"
    add_column :streams, :source_stream_id, :bigint

    add_index :streams, :source_stream_id, unique: true

    add_foreign_key :streams, :streams, column: :source_stream_id, on_delete: :nullify
  end
end
