# class YoutubeChannel < ApplicationRecord
#   belongs_to :owner, class_name: "User", optional: true
#   has_many :streams, dependent: :nullify

#   STATUSES = %w[inactive active].freeze
#   ALLOWED_OWNER_ROLES = %w[stream_operator admin].freeze

#   validates :name, presence: true, length: { maximum: 200 }
#   validates :status, presence: true, inclusion: { in: STATUSES }
#   validates :external_id, uniqueness: true, allow_blank: true

#   validate :owner_role_allowed

#   scope :active, -> { where(status: "active") }
#   scope :inactive, -> { where(status: "inactive") }
#   scope :owned_by, ->(user) { where(owner_id: user.id) }
#   scope :real_channels, -> { where.not(external_id: nil) }
#   scope :available_for_streams, -> { real_channels.active.order(:name) }

#   def connected?
#     oauth_access_token.present? || oauth_refresh_token.present?
#   end

#   def oauth_expired?
#     oauth_expires_at.present? && oauth_expires_at <= Time.current
#   end

#   def connection_state
#     return "Connected" if connected? && !oauth_expired?
#     return "Connected, needs refresh" if connected? && oauth_expired?

#     "Not connected"
#   end

#   def connection_badge_class
#     return "bg-green-50 text-green-700" if connected? && !oauth_expired?
#     return "bg-yellow-50 text-yellow-700" if connected? && oauth_expired?

#     "bg-gray-100 text-gray-600"
#   end

#   def update_tokens!(access_token:, refresh_token: nil, expires_at: nil, scope: nil, token_type: nil)
#     update!(
#       oauth_access_token: access_token,
#       oauth_refresh_token: refresh_token.presence || oauth_refresh_token,
#       oauth_expires_at: expires_at,
#       oauth_scope: scope,
#       oauth_token_type: token_type
#     )
#   end

#   def sync_metadata!
#     if external_id.present?
#       Youtube::ChannelSyncService.new(self).perform
#     else
#       Youtube::ChannelImportService.new(self).call
#     end
#   end

#   def owner_email
#     owner&.email || "—"
#   end

#   def display_name
#     name.presence || "Untitled channel"
#   end

#   private

#   def owner_role_allowed
#     return if owner.nil?
#     return if ALLOWED_OWNER_ROLES.include?(owner.role)

#     errors.add(:owner, "must be a stream_operator or admin")
#   end
# end
class YoutubeChannel < ApplicationRecord
  belongs_to :owner, class_name: "User", optional: true
  has_many :streams, dependent: :nullify

  STATUSES = %w[inactive active].freeze
  ALLOWED_OWNER_ROLES = %w[stream_operator admin].freeze

  validates :name, presence: true, length: { maximum: 200 }
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :external_id, uniqueness: true, allow_blank: true

  validate :owner_role_allowed

  scope :active, -> { where(status: "active") }
  scope :inactive, -> { where(status: "inactive") }
  scope :owned_by, ->(user) { where(owner_id: user.id) }
  scope :real_channels, -> { where.not(external_id: nil) }
  scope :available_for_streams, -> { real_channels.active.order(:name) }

  def connected?
    oauth_access_token.present? || oauth_refresh_token.present?
  end

  def oauth_expired?
    oauth_expires_at.present? && oauth_expires_at <= Time.current
  end

  def connection_state
    return "Connected" if connected? && !oauth_expired?
    return "Connected, needs refresh" if connected? && oauth_expired?

    "Not connected"
  end

  def connection_badge_class
    return "bg-green-50 text-green-700" if connected? && !oauth_expired?
    return "bg-yellow-50 text-yellow-700" if connected? && oauth_expired?

    "bg-gray-100 text-gray-600"
  end

  def update_tokens!(access_token:, refresh_token: nil, expires_at: nil, scope: nil, token_type: nil)
    update!(
      oauth_access_token: access_token,
      oauth_refresh_token: refresh_token.presence || oauth_refresh_token,
      oauth_expires_at: expires_at,
      oauth_scope: scope,
      oauth_token_type: token_type
    )
  end

  def sync_metadata!
    if external_id.present?
      Youtube::ChannelSyncService.new(self).perform
    else
      Youtube::ChannelImportService.new(self).call
    end
  end

  def owner_email
    owner&.email || "—"
  end

  def display_name
    name.presence || "Untitled channel"
  end

  private

  def owner_role_allowed
    return if owner.nil?
    return if ALLOWED_OWNER_ROLES.include?(owner.role)

    errors.add(:owner, "must be a stream_operator or admin")
  end
end
