# class Stream < ApplicationRecord
#   belongs_to :youtube_channel, optional: true

#   STATUSES = %w[scheduled live ended cancelled].freeze

#   validates :title, presence: true
#   validates :status, presence: true, inclusion: { in: STATUSES }
#   validates :scheduled_at, presence: true, if: -> { scheduled? || live? }

#   scope :upcoming, -> { where("scheduled_at >= ?", Time.current).order(scheduled_at: :asc) }
#   scope :past, -> { where("scheduled_at < ?", Time.current).order(scheduled_at: :desc) }
#   scope :live, -> { where(status: "live") }
#   scope :scheduled, -> { where(status: "scheduled") }

#   def channel
#     youtube_channel
#   end

#   def channel=(val)
#     self.youtube_channel = val
#   end

#   def scheduled?
#     status == "scheduled"
#   end

#   def live?
#     status == "live"
#   end
# end
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
  validates :title, presence: true
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
  def thumbnail_url(size = :high)
    return unless thumbnails.present?

    thumbnails[size.to_s]["url"] rescue nil
  end

  # Visibility helpers
  def public?
    visibility == "public"
  end

  def unlisted?
    visibility == "unlisted"
  end

  def private?
    visibility == "private"
  end
end
