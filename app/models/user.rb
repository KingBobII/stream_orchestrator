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

  has_many :youtube_channels, foreign_key: :owner_id, dependent: :nullify

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

  # returns the path the user should be sent to after sign in
  def dashboard_root
    case role
    when "admin"
      Rails.application.routes.url_helpers.admin_dashboard_path
    when "stream_operator"
      Rails.application.routes.url_helpers.stream_operator_dashboard_path
    when "production_operator"
      Rails.application.routes.url_helpers.production_operator_dashboard_path
    else
      Rails.application.routes.url_helpers.authenticated_root_path
    end
  end

  private

  def set_default_role
    self.role ||= "stream_operator"
  end
end
