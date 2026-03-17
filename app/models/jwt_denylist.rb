# app/models/jwt_denylist.rb
class JwtDenylist < ApplicationRecord
  include Devise::JWT::RevocationStrategies::Denylist

  # Rails will map JwtDenylist -> jwt_denylists by default,
  # so no need to set self.table_name unless you have a nonstandard name.
end
