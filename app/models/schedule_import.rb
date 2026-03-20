class ScheduleImport < ApplicationRecord
  has_one_attached :pdf

  enum :status, {
    pending: "pending",
    parsed: "parsed",
    confirmed: "confirmed",
    failed: "failed"
  }, prefix: true

  validates :schedule_date, presence: true
  validate :pdf_attached, on: :create

  def parsed_streams_array
    parsed_streams.is_a?(Array) ? parsed_streams : []
  end

  private

  def pdf_attached
    errors.add(:pdf, "must be attached") unless pdf.attached?
  end
end
