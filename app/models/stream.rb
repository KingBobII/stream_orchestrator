# class Stream < ApplicationRecord
#   belongs_to :youtube_channel

#   # -------------------------
#   # CONSTANTS
#   # -------------------------
#   STATUSES = %w[scheduled live ended cancelled].freeze
#   VISIBILITIES = %w[public unlisted private].freeze

#   # -------------------------
#   # VALIDATIONS
#   # -------------------------
#   validates :title, presence: true
#   validates :status, presence: true, inclusion: { in: STATUSES }
#   validates :visibility, presence: true, inclusion: { in: VISIBILITIES }
#   validates :scheduled_at, presence: true, if: :scheduled?

#   validates :external_video_id, uniqueness: true, allow_blank: true

#   # -------------------------
#   # SCOPES
#   # -------------------------
#   scope :upcoming, -> { where("scheduled_at >= ?", Time.current).order(:scheduled_at) }
#   scope :past, -> { where("scheduled_at < ?", Time.current).order(scheduled_at: :desc) }
#   scope :live, -> { where(status: "live") }
#   scope :scheduled, -> { where(status: "scheduled") }

#   scope :public_streams, -> { where(visibility: "public") }
#   scope :unlisted_streams, -> { where(visibility: "unlisted") }
#   scope :private_streams, -> { where(visibility: "private") }

#   # -------------------------
#   # HELPERS
#   # -------------------------
#   def scheduled?
#     status == "scheduled"
#   end

#   def live?
#     status == "live"
#   end

#   def ended?
#     status == "ended"
#   end

#   # Thumbnail helper (VERY useful for UI)
#   def thumbnail_url(size = :high)
#     return unless thumbnails.present?

#     thumbnails[size.to_s]["url"] rescue nil
#   end

#   # Visibility helpers
#   def public?
#     visibility == "public"
#   end

#   def unlisted?
#     visibility == "unlisted"
#   end

#   def private?
#     visibility == "private"
#   end
# end
# app/models/stream.rb
class Stream < ApplicationRecord
  belongs_to :youtube_channel

  # -------------------------
  # CONSTANTS
  # -------------------------
  STATUSES = %w[scheduled live ended cancelled].freeze
  VISIBILITIES = %w[public unlisted private].freeze

  # -------------------------
  # VALIDATIONS
  # -------------------------
  validates :title, presence: true, length: { maximum: 240 }
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :visibility, presence: true, inclusion: { in: VISIBILITIES }
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

  # -------------------------
  # CALLBACKS
  # -------------------------
  before_validation :strip_title
  before_save :clear_scheduled_at_unless_scheduled

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

  # Thumbnail helper (VERY useful for UI)
  # `thumbnails` is a jsonb column that looks like:
  # { "default": {"url":"..."}, "medium": {...}, "high": {...} }
  def thumbnail_url(size = :high)
    return nil unless thumbnails.present? && thumbnails.is_a?(Hash)

    thumbnails[size.to_s] && thumbnails[size.to_s]["url"]
  rescue
    nil
  end

  # Visibility helpers (keeps your existing method names)
  def public?
    visibility == "public"
  end

  def unlisted?
    visibility == "unlisted"
  end

  def private?
    visibility == "private"
  end

  # Use this to decide if a background job should create a YouTube broadcast
  def needs_scheduling_on_youtube?
    scheduled? && external_video_id.blank?
  end

  # Returns scheduled_at in app-local timezone for display
  def scheduled_at_local
    scheduled_at&.in_time_zone("Africa/Johannesburg")
  end

  # Friendly URL
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
end
