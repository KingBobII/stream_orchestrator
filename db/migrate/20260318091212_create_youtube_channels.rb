class CreateYoutubeChannels < ActiveRecord::Migration[7.0]
  def change
    create_table :youtube_channels do |t|
      t.string :name, null: false
      t.string :external_id
      t.text :description
      t.string :status, null: false, default: "inactive"
      t.datetime :published_at

      t.references :owner, foreign_key: { to_table: :users }, null: true

      t.string :avatar_url
      t.string :banner_url

      t.string :oauth_access_token
      t.string :oauth_refresh_token
      t.datetime :oauth_expires_at

      t.jsonb :settings, default: {}

      t.timestamps
    end

    add_index :youtube_channels, :external_id, unique: true
    add_index :youtube_channels, :name
  end
end
