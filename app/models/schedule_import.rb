class ScheduleImport < ApplicationRecord
  has_one_attached :pdf
  has_many :streams, dependent: :nullify

 enum :status, {
  pending: "pending",
  processing: "processing",
  parsed: "parsed",
  reviewed: "reviewed",
  completed: "completed",
  failed: "failed"
}, default: "pending"

  enum :ai_status, {
    pending: "pending",
    processing: "processing",
    completed: "completed",
    failed: "failed"
  }, default: "pending", prefix: true

  validates :pdf, presence: true

  def parsed_rows_for_review
    Array(parsed_streams).map(&:deep_stringify_keys)
  end

  def cleaned_rows_for_review
    Array(cleaned_streams).map(&:deep_stringify_keys)
  end

  def ready_for_review?
    parsed? && ai_status_completed?
  end

  def finished?
    completed? && ai_status_completed?
  end
end
