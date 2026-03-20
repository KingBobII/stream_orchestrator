# app/controllers/admin/schedule_imports_controller.rb
class Admin::ScheduleImportsController < Admin::BaseController
  def new
    @schedule_import = ScheduleImport.new
  end

  def create
    uploaded_pdf = schedule_import_params[:pdf]

    @schedule_import = ScheduleImport.new(
      schedule_date: schedule_import_params[:schedule_date]
    )

    parsed = ScheduleImports::PdfParser.new(uploaded_pdf.tempfile).call
    Rails.logger.info("Parsed schedule rows: #{parsed[:parsed_streams].size}")

    parsed = ScheduleImports::PdfParser.new(uploaded_pdf.tempfile).call
    @schedule_import.raw_text = parsed[:raw_text]
    @schedule_import.parsed_streams = parsed[:parsed_streams]
    @schedule_import.status = parsed[:parsed_streams].any? ? "parsed" : "failed"

    @schedule_import.pdf.attach(uploaded_pdf)

    if @schedule_import.save
      redirect_to admin_schedule_import_path(@schedule_import), notice: "PDF parsed successfully. Review the parsed streams."
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
  end

  def confirm
    @schedule_import = ScheduleImport.find(params[:id])

    entries =
      confirm_params.fetch(:parsed_streams, {})
                    .sort_by { |index, _| index.to_i }
                    .map { |_, value| value }

    created_streams = []

    Stream.transaction do
      entries.each do |entry|
        scheduled_at = Time.zone.parse("#{@schedule_import.schedule_date} #{entry[:start_time]}")

        created_streams << Stream.create!(
          title: entry[:title],
          description: entry[:description],
          status: "scheduled",
          visibility: entry[:visibility].presence || "public",
          scheduled_at: scheduled_at,
          youtube_channel_id: entry[:youtube_channel_id]
        )
      end

      @schedule_import.update!(status: "confirmed")
    end

    redirect_to admin_schedule_import_path(@schedule_import), notice: "#{created_streams.count} streams created."
  rescue ActiveRecord::RecordInvalid => e
    @youtube_channels = YoutubeChannel.order(:name)
    @schedule_import.errors.add(:base, e.record.errors.full_messages.to_sentence)
    render :show, status: :unprocessable_content
  end

  private

  def schedule_import_params
    params.require(:schedule_import).permit(:pdf, :schedule_date)
  end

  def confirm_params
    params.require(:schedule_import).permit(
      parsed_streams: [
        :title, :description, :location, :start_time, :end_time,
        :visibility, :youtube_channel_id, :raw_text
      ]
    )
  end
end
