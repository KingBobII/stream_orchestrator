class CreateUsers < ActiveRecord::Migration[7.1]
  def change
    create_table :users do |t|
      t.string :email, null: false
      t.string :name
      t.string :role, null: false, default: "stream_operator" # roles: admin, stream_operator, production_operator
      t.string :password_digest, null: false
      t.string :provider # for OAuth later (google)
      t.string :uid

      t.timestamps
    end

    add_index :users, :email, unique: true
    add_index :users, :provider
    add_index :users, :uid
  end
end
