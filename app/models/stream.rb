class Stream < ApplicationRecord
  belongs_to :youtube_channel

  # -------------------------
  # CONSTANTS
  # -------------------------
  STATUSES = %w[scheduled live ended cancelled].freeze
  VISIBILITIES = %w[public unlisted private].freeze
  SYNC_STATUSES = %w[pending syncing synced failed].freeze

  # -------------------------
  # VALIDATIONS
  # -------------------------
  validates :title, presence: true, length: { maximum: 240 }
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :visibility, presence: true, inclusion: { in: VISIBILITIES }
  validates :sync_status, presence: true, inclusion: { in: SYNC_STATUSES }

  validates :scheduled_at, presence: true, if: :scheduled?
  validates :external_video_id, uniqueness: true, allow_blank: true

  # -------------------------
  # SCOPES
  # -------------------------
  scope :upcoming, -> { where("scheduled_at >= ?", Time.current).order(:scheduled_at) }
  scope :past, -> { where("scheduled_at < ?", Time.current).order(scheduled_at: :desc) }
  scope :live, -> { where(status: "live") }
  scope :scheduled, -> { where(status: "scheduled") }

  scope :public_streams, -> { where(visibility: "public") }
  scope :unlisted_streams, -> { where(visibility: "unlisted") }
  scope :private_streams, -> { where(visibility: "private") }

  scope :pending_sync, -> { where(sync_status: "pending") }
  scope :syncing, -> { where(sync_status: "syncing") }
  scope :synced, -> { where(sync_status: "synced") }
  scope :failed_sync, -> { where(sync_status: "failed") }

  scope :unsynced_for_youtube, -> {
    where(status: "scheduled", sync_status: %w[pending failed], external_video_id: nil)
  }

  # -------------------------
  # CALLBACKS
  # -------------------------
  before_validation :strip_title
  before_save :clear_scheduled_at_unless_scheduled
  after_commit :enqueue_youtube_sync_job, on: %i[create update]

  # -------------------------
  # HELPERS
  # -------------------------
  def scheduled?
    status == "scheduled"
  end

  def live?
    status == "live"
  end

  def ended?
    status == "ended"
  end

  def cancelled?
    status == "cancelled"
  end

  def pending_sync?
    sync_status == "pending"
  end

  def syncing?
    sync_status == "syncing"
  end

  def synced?
    sync_status == "synced"
  end

  def failed_sync?
    sync_status == "failed"
  end

  def thumbnail_url(size = :high)
    return nil unless thumbnails.present? && thumbnails.is_a?(Hash)

    thumbnails.dig(size.to_s, "url")
  rescue
    nil
  end

  def public?
    visibility == "public"
  end

  def unlisted?
    visibility == "unlisted"
  end

  def private?
    visibility == "private"
  end

  def needs_scheduling_on_youtube?
    scheduled? && external_video_id.blank? && pending_sync?
  end

  def scheduled_at_local
    scheduled_at&.in_time_zone("Africa/Johannesburg")
  end

  def to_param
    "#{id}-#{title.to_s.parameterize}"
  end

  private

  def strip_title
    self.title = title.strip if title.respond_to?(:strip)
  end

  def clear_scheduled_at_unless_scheduled
    self.scheduled_at = nil unless scheduled?
  end

  def enqueue_youtube_sync_job
    return unless should_enqueue_youtube_sync_job?

    Youtube::SyncStreamJob.perform_later(id)
  end

  def should_enqueue_youtube_sync_job?
    return false unless scheduled?
    return false unless scheduled_at.present?
    return false unless external_video_id.blank?
    return false unless pending_sync?

    previous_changes.key?("id") ||
      previous_changes.key?("status") ||
      previous_changes.key?("scheduled_at") ||
      previous_changes.key?("youtube_channel_id")
  end
end
