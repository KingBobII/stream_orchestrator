# module Admin
#   class StreamsController < Admin::BaseController
#     def index
#       @streams = Stream.order(scheduled_at: :desc)
#     end

#     def show
#       @stream = Stream.find(params[:id])
#     end

#     def new
#       @stream = Stream.new
#     end

#     def create
#       @stream = Stream.new(stream_params)
#       if @stream.save
#         redirect_to admin_stream_path(@stream), notice: "Stream created"
#       else
#         render :new
#       end
#     end

#     def edit
#       @stream = Stream.find(params[:id])
#     end

#     def update
#       @stream = Stream.find(params[:id])
#       if @stream.update(stream_params)
#         redirect_to admin_stream_path(@stream), notice: "Stream updated"
#       else
#         render :edit
#       end
#     end

#     def destroy
#       Stream.find(params[:id]).destroy
#       redirect_to admin_streams_path, notice: "Stream removed"
#     end

#     private

#     def stream_params
#       params.require(:stream).permit(:title, :description, :status, :scheduled_at, :youtube_channel_id, :visibility)
#     end
#   end
# end
# app/controllers/admin/streams_controller.rb
# app/controllers/admin/streams_controller.rb
module Admin
  class StreamsController < Admin::BaseController
    before_action :set_stream, only: %i[show edit update destroy]

    def index
      # avoid N+1 by including the channel; paginate results
      @streams = Stream.includes(:youtube_channel)
                       .order(scheduled_at: :desc)
                       .page(params[:page])
                       .per(params[:per_page] || 15)
    end

    def show; end

    def new
      @stream = Stream.new(status: "scheduled", visibility: "private")
    end

    def create
      @stream = Stream.new(stream_params)
      if @stream.save
        # optional: enqueue job if you want immediate scheduling
        # ScheduleYoutubeBroadcastJob.perform_later(@stream.id) if @stream.needs_scheduling_on_youtube?

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

    private

    def set_stream
      @stream = Stream.find(params[:id])
    end

    def stream_params
      params.require(:stream).permit(:title, :description, :status, :scheduled_at, :youtube_channel_id, :visibility)
    end
  end
end
