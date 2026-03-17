class RenameJwtDenylistToJwtDenylists < ActiveRecord::Migration[7.1]
  def change
    if table_exists?(:jwt_denylist) && !table_exists?(:jwt_denylists)
      rename_table :jwt_denylist, :jwt_denylists
    end
  end
end
