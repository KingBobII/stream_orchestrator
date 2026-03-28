module Admin
  class StreamsController < Admin::BaseController
    before_action :set_stream, only: %i[show edit update destroy sync_to_youtube]

    def index
      base_scope = Stream.includes(:youtube_channel).order(scheduled_at: :desc)

      @pending_sync_count = base_scope
        .where(status: "scheduled")
        .where(sync_status: %w[pending ready failed])
        .where(youtube_broadcast_id: nil)
        .where("scheduled_at > ?", Time.current)
        .count

      if params[:import_id].present?
        @imported_streams = base_scope.where(schedule_import_id: params[:import_id])
        @streams = base_scope.where.not(schedule_import_id: params[:import_id]).page(params[:page]).per(15)
      else
        @imported_streams = Stream.none
        @streams = base_scope.page(params[:page]).per(15)
      end
    end

    def show; end

    def new
      @stream = Stream.new(status: "scheduled", visibility: "private", sync_status: "pending")
    end

    def create
      @stream = Stream.new(stream_params.reverse_merge(
        status: "scheduled",
        visibility: "private",
        sync_status: "pending"
      ))

      if @stream.save
        queue_youtube_sync(@stream)

        notice =
          if @stream.syncable_to_youtube?
            "Stream created and queued for YouTube sync."
          else
            "Stream created, but it is not yet eligible for YouTube sync."
          end

        redirect_to admin_stream_path(@stream), notice: notice
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @stream.update(stream_params)
        queue_youtube_sync(@stream)

        notice =
          if @stream.syncable_to_youtube?
            "Stream updated and queued for YouTube sync."
          else
            "Stream updated, but it is not yet eligible for YouTube sync."
          end

        redirect_to admin_stream_path(@stream), notice: notice
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @stream.destroy
      redirect_to admin_streams_path, notice: "Stream removed"
    end

    def sync_to_youtube
      if @stream.syncable_to_youtube?
        Youtube::SyncStreamJob.perform_later(@stream.id)
        redirect_to admin_stream_path(@stream), notice: "YouTube sync has been queued."
      else
        redirect_to admin_stream_path(@stream), alert: "This stream is not ready for YouTube sync."
      end
    end

    def sync_pending_to_youtube
      streams = Stream.unsynced_for_youtube
      count = streams.count

      streams.find_each do |stream|
        Youtube::SyncStreamJob.perform_later(stream.id)
      end

      redirect_to admin_streams_path, notice: "#{count} stream(s) queued for YouTube sync."
    end

    private

    def set_stream
      @stream = Stream.find(params[:id])
    end

    def stream_params
      params.require(:stream).permit(:title, :description, :status, :scheduled_at, :youtube_channel_id, :visibility)
    end

    def queue_youtube_sync(stream)
      return unless stream.syncable_to_youtube?

      Youtube::SyncStreamJob.perform_later(stream.id)
    end
  end
end
