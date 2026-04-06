# class Stream < ApplicationRecord
#   belongs_to :youtube_channel
#   belongs_to :schedule_import, optional: true

#   STATUSES = %w[scheduled live ended cancelled].freeze
#   VISIBILITIES = %w[public unlisted private].freeze
#   SYNC_STATUSES = %w[pending ready syncing synced failed].freeze
#   VENUE_TYPES = %w[virtual physical hybrid].freeze

#   validates :title, presence: true, length: { maximum: 240 }
#   validates :status, presence: true, inclusion: { in: STATUSES }
#   validates :visibility, presence: true, inclusion: { in: VISIBILITIES }
#   validates :sync_status, presence: true, inclusion: { in: SYNC_STATUSES }
#   validates :venue_type, presence: true, inclusion: { in: VENUE_TYPES }

#   validates :scheduled_at, presence: true, if: :scheduled?
#   validates :youtube_channel, presence: true

#   validates :youtube_broadcast_id, uniqueness: true, allow_blank: true
#   validates :youtube_stream_id, uniqueness: true, allow_blank: true
#   validates :youtube_video_id, uniqueness: true, allow_blank: true
#   validates :youtube_watch_url, uniqueness: true, allow_blank: true

#   validate :youtube_sync_fields_present_when_synced

#   scope :upcoming, -> { where("scheduled_at >= ?", Time.current).order(:scheduled_at) }
#   scope :past, -> { where("scheduled_at < ?", Time.current).order(scheduled_at: :desc) }
#   scope :live, -> { where(status: "live") }
#   scope :scheduled, -> { where(status: "scheduled") }

#   scope :public_streams, -> { where(visibility: "public") }
#   scope :unlisted_streams, -> { where(visibility: "unlisted") }
#   scope :private_streams, -> { where(visibility: "private") }

#   scope :pending_sync, -> { where(sync_status: "pending") }
#   scope :ready_for_sync, -> { where(sync_status: "ready") }
#   scope :syncing, -> { where(sync_status: "syncing") }
#   scope :synced, -> { where(sync_status: "synced") }
#   scope :failed_sync, -> { where(sync_status: "failed") }

#   scope :visible_to, ->(user) {
#     joins(:youtube_channel).merge(YoutubeChannel.visible_to(user))
#   }

#   scope :unsynced_for_youtube, lambda {
#     scheduled
#       .where(sync_status: %w[pending ready failed])
#       .where(youtube_broadcast_id: nil)
#       .where("scheduled_at > ?", Time.current)
#       .joins(:youtube_channel)
#       .merge(YoutubeChannel.where(status: "active").where.not(external_id: nil))
#   }

#   scope :with_youtube_schedule_data, -> { where.not(youtube_broadcast_id: nil).order(:scheduled_at) }

#   before_validation :strip_title

#   def scheduled?
#     status == "scheduled"
#   end

#   def live?
#     status == "live"
#   end

#   def ended?
#     status == "ended"
#   end

#   def cancelled?
#     status == "cancelled"
#   end

#   def pending_sync?
#     sync_status == "pending"
#   end

#   def ready_for_sync?
#     sync_status == "ready"
#   end

#   def syncing?
#     sync_status == "syncing"
#   end

#   def synced?
#     sync_status == "synced"
#   end

#   def failed_sync?
#     sync_status == "failed"
#   end

#   def public?
#     visibility == "public"
#   end

#   def unlisted?
#     visibility == "unlisted"
#   end

#   def private?
#     visibility == "private"
#   end

#   def syncable_to_youtube?
#     scheduled? &&
#       title.present? &&
#       scheduled_at.present? &&
#       scheduled_at.future? &&
#       youtube_channel.present? &&
#       youtube_channel.connected? &&
#       youtube_channel.status == "active" &&
#       youtube_channel.external_id.present?
#   end

#   def needs_scheduling_on_youtube?
#     syncable_to_youtube? && youtube_broadcast_id.blank?
#   end

#   def needs_update_on_youtube?
#     syncable_to_youtube? && youtube_broadcast_id.present?
#   end

#   def thumbnail_url(size = :high)
#     return nil unless thumbnails.is_a?(Hash)

#     thumbnails.dig(size.to_s, "url")
#   end

#   def watch_url
#     youtube_watch_url.presence || fallback_watch_url
#   end

#   def scheduled_at_local
#     scheduled_at&.in_time_zone("Africa/Johannesburg")
#   end

#   def venue_display_name
#     return venue_name if venue_type == "physical" && venue_name.present?
#     return "Hybrid" if venue_type == "hybrid"

#     "Virtual"
#   end

#   def youtube_stream_key
#     youtube_stream_name
#   end

#   def youtube_rtmp_url
#     youtube_ingestion_address
#   end

#   def to_param
#     "#{id}-#{title.to_s.parameterize}"
#   end

#   private

#   def strip_title
#     self.title = title.strip if title.respond_to?(:strip)
#   end

#   def fallback_watch_url
#     return nil if youtube_video_id.blank?

#     "https://www.youtube.com/watch?v=#{youtube_video_id}"
#   end

#   def youtube_sync_fields_present_when_synced
#     return unless synced?

#     errors.add(:youtube_broadcast_id, "can't be blank") if youtube_broadcast_id.blank?
#     errors.add(:youtube_stream_id, "can't be blank") if youtube_stream_id.blank?
#     errors.add(:youtube_video_id, "can't be blank") if youtube_video_id.blank?
#     errors.add(:youtube_watch_url, "can't be blank") if youtube_watch_url.blank?
#   end
# end
class Stream < ApplicationRecord
  belongs_to :youtube_channel
  belongs_to :schedule_import, optional: true
  belongs_to :source_stream, class_name: "Stream", optional: true, inverse_of: :public_stream

  has_one :public_stream,
          class_name: "Stream",
          foreign_key: :source_stream_id,
          dependent: :nullify,
          inverse_of: :source_stream

  STATUSES = %w[scheduled live ended cancelled].freeze
  VISIBILITIES = %w[public unlisted private].freeze
  SYNC_STATUSES = %w[pending ready syncing synced failed].freeze
  VENUE_TYPES = %w[virtual physical hybrid].freeze
  STREAM_KINDS = %w[public source].freeze

  validates :title, presence: true, length: { maximum: 240 }
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :visibility, presence: true, inclusion: { in: VISIBILITIES }
  validates :sync_status, presence: true, inclusion: { in: SYNC_STATUSES }
  validates :venue_type, presence: true, inclusion: { in: VENUE_TYPES }
  validates :stream_kind, presence: true, inclusion: { in: STREAM_KINDS }

  validates :scheduled_at, presence: true, if: :scheduled?
  validates :youtube_channel, presence: true

  validates :youtube_broadcast_id, uniqueness: true, allow_blank: true
  validates :youtube_stream_id, uniqueness: true, allow_blank: true
  validates :youtube_video_id, uniqueness: true, allow_blank: true
  validates :youtube_watch_url, uniqueness: true, allow_blank: true
  validates :source_stream_id, uniqueness: true, allow_blank: true

  validate :youtube_sync_fields_present_when_synced
  validate :source_stream_consistency

  scope :upcoming, -> { where("scheduled_at >= ?", Time.current).order(:scheduled_at) }
  scope :past, -> { where("scheduled_at < ?", Time.current).order(scheduled_at: :desc) }
  scope :live, -> { where(status: "live") }
  scope :scheduled, -> { where(status: "scheduled") }

  scope :public_streams, -> { where(visibility: "public") }
  scope :unlisted_streams, -> { where(visibility: "unlisted") }
  scope :private_streams, -> { where(visibility: "private") }

  scope :public_kind, -> { where(stream_kind: "public") }
  scope :source_kind, -> { where(stream_kind: "source") }

  scope :pending_sync, -> { where(sync_status: "pending") }
  scope :ready_for_sync, -> { where(sync_status: "ready") }
  scope :syncing, -> { where(sync_status: "syncing") }
  scope :synced, -> { where(sync_status: "synced") }
  scope :failed_sync, -> { where(sync_status: "failed") }

  scope :visible_to, ->(user) {
    joins(:youtube_channel).merge(YoutubeChannel.visible_to(user))
  }

  scope :unsynced_for_youtube, lambda {
    scheduled
      .where(sync_status: %w[pending ready failed])
      .where(youtube_broadcast_id: nil)
      .where("scheduled_at > ?", Time.current)
      .joins(:youtube_channel)
      .merge(YoutubeChannel.where(status: "active").where.not(external_id: nil))
  }

  scope :with_youtube_schedule_data, -> { where.not(youtube_broadcast_id: nil).order(:scheduled_at) }

  before_validation :strip_title
  before_validation :set_default_stream_kind, on: :create

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

  def public_stream_kind?
    stream_kind == "public"
  end

  def source_stream_kind?
    stream_kind == "source"
  end

  def requires_source_stream?
    public_stream_kind? && venue_type.in?(%w[physical hybrid]) && source_stream.blank?
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

  def venue_display_name
    return venue_name if venue_type == "physical" && venue_name.present?
    return "Hybrid" if venue_type == "hybrid"

    "Virtual"
  end

  def youtube_stream_key
    youtube_stream_name
  end

  def youtube_rtmp_url
    youtube_ingestion_address
  end

  def source_stream_title
    base_title = title.to_s.sub(/\A\(source\)\s*/i, "").strip
    "(source)#{base_title}"[0, 240]
  end

  def source_stream_description
    venue_name.presence
  end

  def to_param
    "#{id}-#{title.to_s.parameterize}"
  end

  private

  def strip_title
    self.title = title.strip if title.respond_to?(:strip)
  end

  def set_default_stream_kind
    self.stream_kind ||= "public"
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

  def source_stream_consistency
    return if source_stream_id.blank?

    errors.add(:source_stream, "cannot point to itself") if source_stream_id == id
    errors.add(:source_stream, "must be a source stream") if source_stream.present? && !source_stream.source_stream_kind?
    errors.add(:source_stream, "cannot be set on a source stream") if source_stream_kind?
  end
end
