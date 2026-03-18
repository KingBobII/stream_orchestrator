class CreateStreams < ActiveRecord::Migration[7.0]
  def change
    create_table :streams do |t|
      t.string :title, null: false
      t.text :description

      # internal app state
      t.string :status, null: false, default: "scheduled"
      # scheduled / live / ended / cancelled

      # YouTube visibility
      t.string :visibility, null: false, default: "private"
      # public / unlisted / private

      t.datetime :scheduled_at

      t.references :youtube_channel, foreign_key: true, null: false

      # YouTube video ID
      t.string :external_video_id

      # thumbnails from YouTube API
      t.jsonb :thumbnails, default: {}

      t.timestamps
    end

    add_index :streams, :external_video_id, unique: true
    add_index :streams, :status
    add_index :streams, :visibility
    add_index :streams, :scheduled_at
  end
end
