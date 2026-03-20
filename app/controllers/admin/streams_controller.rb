# module Admin
#   class StreamsController < Admin::BaseController
#     before_action :set_stream, only: %i[show edit update destroy sync_to_youtube]

#     # def index
#     #   @streams = Stream.includes(:youtube_channel)
#     #                    .order(scheduled_at: :desc)
#     #                    .page(params[:page])
#     #                    .per(params[:per_page] || 15)

#     #   @pending_sync_count = Stream.where(status: "scheduled", sync_status: %w[pending failed], external_video_id: nil).count
#     # end
#     def index
#       @streams = Stream.includes(:youtube_channel)
#                     .order(scheduled_at: :desc)
#                     .page(params[:page])
#                     .per(params[:per_page] || 15)

#       @pending_sync_count = Stream.unsynced_for_youtube.count
#     end

#     def show; end

#     def new
#       @stream = Stream.new(status: "scheduled", visibility: "private", sync_status: "pending")
#     end

#     def create
#       @stream = Stream.new(stream_params)

#       if @stream.save
#         redirect_to admin_stream_path(@stream), notice: "Stream created"
#       else
#         render :new, status: :unprocessable_entity
#       end
#     end

#     def edit; end

#     def update
#       if @stream.update(stream_params)
#         redirect_to admin_stream_path(@stream), notice: "Stream updated"
#       else
#         render :edit, status: :unprocessable_entity
#       end
#     end

#     def destroy
#       @stream.destroy
#       redirect_to admin_streams_path, notice: "Stream removed"
#     end

#     def sync_to_youtube
#       if @stream.needs_scheduling_on_youtube?
#         Youtube::SyncStreamJob.perform_later(@stream.id)
#         redirect_to admin_stream_path(@stream), notice: "YouTube sync has been queued."
#       else
#         redirect_to admin_stream_path(@stream), alert: "This stream is not ready for YouTube sync."
#       end
#     end

#     # def sync_pending_to_youtube
#     #   streams = Stream.where(status: "scheduled", sync_status: %w[pending failed], external_video_id: nil)

#     #   count = streams.count
#     #   streams.find_each do |stream|
#     #     Youtube::SyncStreamJob.perform_later(stream.id)
#     #   end

#     #   redirect_to admin_streams_path, notice: "#{count} stream(s) queued for YouTube sync."
#     # end
#     def sync_pending_to_youtube
#       streams = Stream.unsynced_for_youtube
#       count = streams.count

#       streams.find_each do |stream|
#         Youtube::SyncStreamJob.perform_later(stream.id)
#       end

#       redirect_to admin_streams_path, notice: "#{count} stream(s) queued for YouTube sync."
#     end

#     private

#     def set_stream
#       @stream = Stream.find(params[:id])
#     end

#     def stream_params
#       params.require(:stream).permit(:title, :description, :status, :scheduled_at, :youtube_channel_id, :visibility)
#     end
#   end
# end
module Admin
  class StreamsController < Admin::BaseController
    before_action :set_stream, only: %i[show edit update destroy sync_to_youtube]

    # def index
    #   @streams = Stream.includes(:youtube_channel)
    #                    .order(scheduled_at: :desc)
    #                    .page(params[:page])
    #                    .per(params[:per_page] || 15)

    #   @pending_sync_count = Stream.unsynced_for_youtube.count
    # end
    def index
      base_scope = Stream.includes(:youtube_channel).order(scheduled_at: :desc)

      @pending_sync_count = base_scope.where(status: "scheduled")
                                      .where(sync_status: %w[pending failed])
                                      .where(external_video_id: nil)
                                      .count

      if params[:import_id].present?
        @imported_streams = base_scope.where(schedule_import_id: params[:import_id])
        @streams = base_scope.where.not(schedule_import_id: params[:import_id]).page(params[:page]).per(15)
      else
        @imported_streams = []
        @streams = base_scope.page(params[:page]).per(15)
      end
    end

    def show; end

    def new
      @stream = Stream.new(status: "scheduled", visibility: "private", sync_status: "pending")
    end

    def create
      @stream = Stream.new(stream_params)

      if @stream.save
        redirect_to admin_stream_path(@stream), notice: "Stream created"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @stream.update(stream_params)
        redirect_to admin_stream_path(@stream), notice: "Stream updated"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @stream.destroy
      redirect_to admin_streams_path, notice: "Stream removed"
    end

    def sync_to_youtube
      if @stream.needs_scheduling_on_youtube?
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
  end
end
