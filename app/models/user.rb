class User < ApplicationRecord
  has_secure_password

  # roles: admin, stream_operator, production_operator
  ROLES = %w[admin stream_operator production_operator].freeze

  validates :email, presence: true, uniqueness: true, format: URI::MailTo::EMAIL_REGEXP
  validates :role, presence: true, inclusion: { in: ROLES }
  validates :password, length: { minimum: 6 }, if: -> { new_record? || !password.nil? }

  # simple JWT helper for issuing tokens
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
