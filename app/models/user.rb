# app/models/user.rb
class User < ApplicationRecord
  devise :database_authenticatable,
         :registerable,
         :recoverable,
         :rememberable,
         :validatable,
         :jwt_authenticatable,
         jwt_revocation_strategy: JwtDenylist

  ROLES = %w[admin stream_operator production_operator].freeze

  validates :role, presence: true, inclusion: { in: ROLES }

  before_validation :set_default_role, on: :create

  scope :admins, -> { where(role: "admin") }
  scope :stream_operators, -> { where(role: "stream_operator") }
  scope :production_operators, -> { where(role: "production_operator") }

  def admin?
    role == "admin"
  end

  def stream_operator?
    role == "stream_operator"
  end

  def production_operator?
    role == "production_operator"
  end

  def self.role_options
    ROLES.map { |r| [r.humanize, r] }
  end

  private

  def set_default_role
    self.role ||= "stream_operator"
  end
end
