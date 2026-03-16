# app/models/user.rb
class User < ApplicationRecord
  # Devise modules.
  # Keep :registerable if you want web sign-up; remove it to make sign-ups admin-only.
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :trackable,
         :jwt_authenticatable, jwt_revocation_strategy: JwtDenylist

  # roles
  ROLES = %w[admin stream_operator production_operator].freeze

  validates :role, presence: true, inclusion: { in: ROLES }

  # Keep helper if needed elsewhere
  def generate_jwt(exp = 24.hours.from_now)
    payload = { user_id: id, exp: exp.to_i }
    JWT.encode(payload, Rails.application.credentials.secret_key_base)
  end

  def admin?
    role == "admin"
  end

  def stream_operator?
    role == "stream_operator"
  end

  def production_operator?
    role == "production_operator"
  end
end
