class Stream < ApplicationRecord
  belongs_to :youtube_channel
  belongs_to :schedule_import, optional: true

  STATUSES = %w[scheduled live ended cancelled].freeze
  VISIBILITIES = %w[public unlisted private].freeze
  SYNC_STATUSES = %w[pending ready syncing synced failed].freeze

  validates :title, presence: true, length: { maximum: 240 }
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :visibility, presence: true, inclusion: { in: VISIBILITIES }
  validates :sync_status, presence: true, inclusion: { in: SYNC_STATUSES }

  validates :scheduled_at, presence: true, if: :scheduled?
  validates :youtube_channel, presence: true

  validates :youtube_broadcast_id, uniqueness: true, allow_blank: true
  validates :youtube_stream_id, uniqueness: true, allow_blank: true
  validates :youtube_video_id, uniqueness: true, allow_blank: true
  validates :youtube_watch_url, uniqueness: true, allow_blank: true

  validate :youtube_sync_fields_present_when_synced

  scope :upcoming, -> { where("scheduled_at >= ?", Time.current).order(:scheduled_at) }
  scope :past, -> { where("scheduled_at < ?", Time.current).order(scheduled_at: :desc) }
  scope :live, -> { where(status: "live") }
  scope :scheduled, -> { where(status: "scheduled") }

  scope :public_streams, -> { where(visibility: "public") }
  scope :unlisted_streams, -> { where(visibility: "unlisted") }
  scope :private_streams, -> { where(visibility: "private") }

  scope :pending_sync, -> { where(sync_status: "pending") }
  scope :ready_for_sync, -> { where(sync_status: "ready") }
  scope :syncing, -> { where(sync_status: "syncing") }
  scope :synced, -> { where(sync_status: "synced") }
  scope :failed_sync, -> { where(sync_status: "failed") }

  scope :unsynced_for_youtube, lambda {
    scheduled
      .where(sync_status: %w[pending ready failed])
      .where(youtube_broadcast_id: nil)
      .where("scheduled_at > ?", Time.current)
      .joins(:youtube_channel)
      .merge(YoutubeChannel.where(status: "active").where.not(external_id: nil))
  }

  before_validation :strip_title

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

  def ready_for_sync?
    sync_status == "ready"
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

  def public?
    visibility == "public"
  end

  def unlisted?
    visibility == "unlisted"
  end

  def private?
    visibility == "private"
  end

  def syncable_to_youtube?
    scheduled? &&
      title.present? &&
      scheduled_at.present? &&
      scheduled_at.future? &&
      youtube_channel.present? &&
      youtube_channel.connected? &&
      youtube_channel.status == "active" &&
      youtube_channel.external_id.present?
  end

  def needs_scheduling_on_youtube?
    syncable_to_youtube? && youtube_broadcast_id.blank?
  end

  def needs_update_on_youtube?
    syncable_to_youtube? && youtube_broadcast_id.present?
  end

  def thumbnail_url(size = :high)
    return nil unless thumbnails.is_a?(Hash)

    thumbnails.dig(size.to_s, "url")
  end

  def watch_url
    youtube_watch_url.presence || fallback_watch_url
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

  def fallback_watch_url
    return nil if youtube_video_id.blank?

    "https://www.youtube.com/watch?v=#{youtube_video_id}"
  end

  def youtube_sync_fields_present_when_synced
    return unless synced?

    errors.add(:youtube_broadcast_id, "can't be blank") if youtube_broadcast_id.blank?
    errors.add(:youtube_stream_id, "can't be blank") if youtube_stream_id.blank?
    errors.add(:youtube_video_id, "can't be blank") if youtube_video_id.blank?
    errors.add(:youtube_watch_url, "can't be blank") if youtube_watch_url.blank?
  end
end
