class Admin::ScheduleImportsController < Admin::BaseController
  def new
    @schedule_import = ScheduleImport.new
  end

  def create
    uploaded_pdf = schedule_import_params[:pdf]

    @schedule_import = ScheduleImport.new(
      schedule_date: schedule_import_params[:schedule_date]
    )

    @schedule_import.pdf.attach(uploaded_pdf)

    parsed = ScheduleImports::PdfParser.new(uploaded_pdf.tempfile).call
    Rails.logger.info("Parsed schedule rows: #{parsed[:parsed_streams].size}")

    cleaned_streams = ScheduleImports::AiCleaner.call(parsed[:parsed_streams])
    Rails.logger.info("AI cleaned rows: #{cleaned_streams.inspect}")

    @schedule_import.raw_text = parsed[:raw_text]
    @schedule_import.parsed_streams = parsed[:parsed_streams]
    @schedule_import.cleaned_streams = cleaned_streams
    @schedule_import.status = parsed[:parsed_streams].any? ? "parsed" : "failed"
    @schedule_import.ai_status = cleaned_streams.any? ? "completed" : "failed"
    @schedule_import.ai_model = ENV.fetch("OPENAI_CLEANUP_MODEL", "gpt-4o-mini")
    @schedule_import.ai_processed_at = Time.current

    if @schedule_import.save
      redirect_to admin_schedule_import_path(@schedule_import), notice: "PDF parsed and cleaned successfully. Review the cleaned streams."
    else
      render :new, status: :unprocessable_content
    end
  rescue StandardError => e
    Rails.logger.error(e.full_message)

    @schedule_import ||= ScheduleImport.new(schedule_date: schedule_import_params[:schedule_date])
    @schedule_import.errors.add(:base, e.message)
    render :new, status: :unprocessable_content
  end

  def show
    @schedule_import = ScheduleImport.find(params[:id])
    @youtube_channels = YoutubeChannel.order(:name)
    @raw_rows = @schedule_import.parsed_rows_for_review
    @cleaned_rows = @schedule_import.cleaned_rows_for_review
  end

#  def confirm
#     @schedule_import = ScheduleImport.find(params[:id])
#     @youtube_channels = YoutubeChannel.order(:name)
#     @raw_rows = @schedule_import.parsed_rows_for_review
#     @cleaned_rows = @schedule_import.cleaned_rows_for_review

#     rows = confirm_params.fetch(:rows, {}).to_h

#     entries = rows
#       .sort_by { |index, _| index.to_i }
#       .map { |_, value| value.to_h }

#     created_streams = []

#     Stream.transaction do
#       entries.each do |entry|
#         scheduled_at = parse_scheduled_at(entry)

#         created_streams << Stream.create!(
#           title: entry[:title].presence || entry["title"],
#           description: entry[:description].presence || entry["description"],
#           status: "scheduled",
#           visibility: entry[:visibility].presence || entry["visibility"] || "public",
#           scheduled_at: scheduled_at,
#           youtube_channel_id: entry[:youtube_channel_id].presence || entry["youtube_channel_id"]
#         )
#       end

#       @schedule_import.update!(status: "completed")
#     end

#     redirect_to admin_schedule_import_path(@schedule_import), notice: "#{created_streams.count} streams created."
#   rescue ActiveRecord::RecordInvalid => e
#   Rails.logger.error("Stream validation failed: #{e.record.errors.full_messages.to_sentence}")
#   @schedule_import.errors.add(:base, e.record.errors.full_messages.to_sentence)
#   render :show, status: :unprocessable_content
#   rescue StandardError => e
#     Rails.logger.error(e.full_message)
#     @schedule_import.errors.add(:base, e.message)
#     render :show, status: :unprocessable_content
#   end
  # def confirm
  #   @schedule_import = ScheduleImport.find(params[:id])
  #   @youtube_channels = YoutubeChannel.order(:name)
  #   @raw_rows = @schedule_import.parsed_rows_for_review
  #   @cleaned_rows = @schedule_import.cleaned_rows_for_review

  #   rows = confirm_params.fetch(:rows, {}).to_h

  #   entries = rows
  #     .sort_by { |index, _| index.to_i }
  #     .map { |_, value| value.to_h }

  #   created_streams = []

  #   Stream.transaction do
  #     entries.each do |entry|
  #       scheduled_at = parse_scheduled_at(entry)

  #       created_streams << Stream.create!(
  #         title: entry[:title].presence || entry["title"],
  #         description: entry[:description].presence || entry["description"],
  #         status: "scheduled",
  #         visibility: entry[:visibility].presence || entry["visibility"] || "public",
  #         scheduled_at: scheduled_at,
  #         youtube_channel_id: entry[:youtube_channel_id].presence || entry["youtube_channel_id"],
  #         schedule_import: @schedule_import
  #       )
  #     end

  #     @schedule_import.update!(status: "completed")
  #   end

  #   redirect_to admin_streams_path(import_id: @schedule_import.id),
  #               notice: "#{created_streams.count} streams created."
  # rescue ActiveRecord::RecordInvalid => e
  #   @schedule_import.errors.add(:base, e.record.errors.full_messages.to_sentence)
  #   render :show, status: :unprocessable_content
  # rescue StandardError => e
  #   Rails.logger.error(e.full_message)
  #   @schedule_import.errors.add(:base, e.message)
  #   render :show, status: :unprocessable_content
  # end

def confirm
  @schedule_import = ScheduleImport.find(params[:id])
  @youtube_channels = YoutubeChannel.order(:name)
  @raw_rows = @schedule_import.parsed_rows_for_review
  @cleaned_rows = @schedule_import.cleaned_rows_for_review

  rows = confirm_params.fetch(:rows, {}).to_h

  entries = rows
    .sort_by { |index, _| index.to_i }
    .map { |_, value| value.to_h }

  created_streams = []

  Stream.transaction do
    entries.each do |entry|
      scheduled_at = parse_scheduled_at(entry)

      created_streams << Stream.create!(
        title: entry[:title].presence || entry["title"],
        description: entry[:description].presence || entry["description"],
        status: "scheduled",
        visibility: entry[:visibility].presence || entry["visibility"] || "public",
        scheduled_at: scheduled_at,
        youtube_channel_id: entry[:youtube_channel_id].presence || entry["youtube_channel_id"],
        schedule_import: @schedule_import,
        sync_status: "pending"
      )
    end

    @schedule_import.update!(status: "completed")
  end

  created_streams.each do |stream|
    stream.update!(sync_status: "ready")
    Youtube::SyncStreamJob.perform_later(stream.id)
  end

  redirect_to admin_streams_path(import_id: @schedule_import.id),
              notice: "#{created_streams.count} streams created."
rescue ActiveRecord::RecordInvalid => e
  @schedule_import.errors.add(:base, e.record.errors.full_messages.to_sentence)
  render :show, status: :unprocessable_content
rescue StandardError => e
  Rails.logger.error(e.full_message)
  @schedule_import.errors.add(:base, e.message)
  render :show, status: :unprocessable_content
end
  private

  def schedule_import_params
    params.require(:schedule_import).permit(:pdf, :schedule_date)
  end

  def confirm_params
    params.require(:schedule_import).permit(
      rows: [
        :title, :description, :location, :start_time, :end_time,
        :time_text, :date_text, :scheduled_at,
        :visibility, :youtube_channel_id, :raw_text,
        :raw_title, :raw_description, :committee, :notes
      ]
    )
  end

  def parse_scheduled_at(entry)
    date_part =
      @schedule_import.schedule_date.presence ||
      entry[:date_text].presence ||
      entry["date_text"].presence

    time_part =
      entry[:start_time].presence ||
      entry["start_time"].presence ||
      entry[:time_text].presence ||
      entry["time_text"].presence

    return nil if date_part.blank? || time_part.blank?

    # If the time text is a range like "09:00 - 12:00", use the first time.
    time_part = time_part.to_s.split(" - ").first.strip

    Time.zone.parse("#{date_part} #{time_part}")
  rescue ArgumentError, TypeError
    nil
  end
end
