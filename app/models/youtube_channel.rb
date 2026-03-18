class YoutubeChannel < ApplicationRecord
  belongs_to :owner, class_name: "User", optional: true
  has_many :streams, dependent: :nullify

  STATUSES = %w[inactive active].freeze

  validates :name, presence: true, length: { maximum: 200 }
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :external_id, uniqueness: true, allow_blank: true

  scope :active, -> { where(status: "active") }
  scope :owned_by, ->(user) { where(owner_id: user.id) }

  # ensure owner is correct role if present
  validate :owner_role_allowed

  # utils
  def connected?
    oauth_refresh_token.present? || oauth_access_token.present?
  end

  def update_tokens!(access_token:, refresh_token:, expires_at: nil)
    update!(
      oauth_access_token: access_token,
      oauth_refresh_token: refresh_token.presence || oauth_refresh_token,
      oauth_expires_at: expires_at
    )
  end

  def sync_metadata!
    YoutubeChannelSyncService.new(self).perform_metadata_sync
  end

  def owner_email
    owner&.email || "—"
  end

  private

  ALLOWED_OWNER_ROLES = %w[stream_operator admin].freeze

  def owner_role_allowed
    return if owner.nil?
    return if ALLOWED_OWNER_ROLES.include?(owner.role)

    errors.add(:owner, "must be a stream_operator or admin")
  end
end
