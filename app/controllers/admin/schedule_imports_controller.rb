class Admin::ScheduleImportsController < Admin::BaseController
  before_action :set_schedule_import, only: %i[show confirm]

  def new
    @schedule_import = ScheduleImport.new
  end

  def create
    uploaded_pdf = schedule_import_params[:pdf]

    @schedule_import = ScheduleImport.new(
      schedule_date: schedule_import_params[:schedule_date],
      status: "pending",
      ai_status: "pending"
    )

    @schedule_import.pdf.attach(uploaded_pdf)

    if @schedule_import.save

      ScheduleImports::ProcessPdfJob.perform_later(@schedule_import.id)

     
      redirect_to processing_admin_schedule_import_path(@schedule_import),
                  notice: "Schedule upload started. Processing in progress..."
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
    load_review_data
  end

  def confirm
    load_review_data

    rows = confirm_params.fetch(:rows, {}).to_h
    entries = rows.sort_by { |index, _| index.to_i }.map { |_, value| value.to_h }
    entries = normalize_rows_with_scheduled_at(entries)

    if entries.empty?
      @schedule_import.errors.add(:base, "No rows were submitted.")
      render :show, status: :unprocessable_content and return
    end

    created_streams = []

    Stream.transaction do
      entries.each_with_index do |entry, index|
        youtube_channel_id = entry["youtube_channel_id"].presence || entry[:youtube_channel_id].presence
        youtube_channel = @youtube_channels.find_by(id: youtube_channel_id)

        unless youtube_channel&.connected? &&
               youtube_channel.status == "active" &&
               youtube_channel.external_id.present?
          @schedule_import.errors.add(:base, "Item #{index + 1}: please select a connected YouTube channel.")
          raise ActiveRecord::Rollback
        end

        created_streams.concat(
          Array(
            ScheduleImports::StreamCreator.call(
              rows: [entry],
              schedule_import: @schedule_import,
              youtube_channel: youtube_channel
            )
          )
        )
      end

      @schedule_import.update!(status: "completed") if @schedule_import.errors.empty?
    end

    if @schedule_import.errors.any?
      render :show, status: :unprocessable_content and return
    end

    created_streams.each do |stream|
      next unless stream.syncable_to_youtube?

      Youtube::SyncStreamJob.perform_later(stream.id)
    end

    redirect_to admin_streams_path(import_id: @schedule_import.id),
                notice: "#{created_streams.count} stream(s) created and queued for YouTube sync.",
                status: :see_other
  rescue ActiveRecord::RecordInvalid => e
    @schedule_import.errors.add(:base, e.record.errors.full_messages.to_sentence.presence || e.message)
    render :show, status: :unprocessable_content
  rescue StandardError => e
    Rails.logger.error(e.full_message)
    @schedule_import.errors.add(:base, e.message)
    render :show, status: :unprocessable_content
  end


  def processing
    @schedule_import = ScheduleImport.find(params[:id])
  end

  def status
    schedule_import = ScheduleImport.find(params[:id])

    render json: {
      status: schedule_import.status,
      ai_status: schedule_import.ai_status
    }
  end
  private

  def set_schedule_import
    @schedule_import = ScheduleImport.find(params[:id])
  end

  def load_review_data
    @youtube_channels = YoutubeChannel.available_for_streams
    @raw_rows = Array(@schedule_import.parsed_rows_for_review)
    @cleaned_rows = normalize_rows_with_scheduled_at(Array(@schedule_import.cleaned_rows_for_review))
  end

  def normalize_rows_with_scheduled_at(rows)
    Array(rows).map.with_index do |row, index|
      row = row.deep_stringify_keys
      row["index"] ||= index + 1

      current_value = row["scheduled_at"]
      row["scheduled_at"] =
        if current_value.respond_to?(:strftime)
          current_value.strftime("%Y-%m-%d %H:%M")
        else
          current_value.presence || parse_scheduled_at(row)
        end

      row
    end
  end

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
      entry["date_text"].presence ||
      entry[:date_text].presence

    time_part =
      entry["scheduled_at"].presence ||
      entry[:scheduled_at].presence ||
      entry["time_text"].presence ||
      entry[:time_text].presence ||
      entry["start_time"].presence ||
      entry[:start_time].presence

    return nil if date_part.blank? || time_part.blank?

    time_part = time_part.to_s.split(" - ").first.strip
    Time.zone.parse("#{date_part} #{time_part}")&.strftime("%Y-%m-%d %H:%M")
  rescue ArgumentError, TypeError
    nil
  end
end
