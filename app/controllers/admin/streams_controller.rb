# module Admin
#   class StreamsController < Admin::ApplicationController
#     before_action :set_stream, only: %i[show edit update destroy]

#     def index
#       @streams = Stream.includes(:youtube_channel).order(scheduled_at: :desc).page(params[:page])
#     end

#     def show; end

#     def new
#       @stream = Stream.new
#     end

#     def create
#       @stream = Stream.new(stream_params)
#       if @stream.save
#         redirect_to admin_stream_path(@stream), notice: "Stream created."
#       else
#         render :new, status: :unprocessable_entity
#       end
#     end

#     def edit; end

#     def update
#       if @stream.update(stream_params)
#         redirect_to admin_stream_path(@stream), notice: "Stream updated."
#       else
#         render :edit, status: :unprocessable_entity
#       end
#     end

#     def destroy
#       @stream.destroy
#       redirect_to admin_streams_path, notice: "Stream removed."
#     end

#     private

#     def set_stream
#       @stream = Stream.find(params[:id])
#     end

#     def stream_params
#       params.require(:stream).permit(:title, :description, :status, :scheduled_at, :duration_minutes, :youtube_channel_id, :external_video_id, :thumbnails)
#     end
#   end
# end
module Admin
  class StreamsController < Admin::BaseController
    def index
      @streams = Stream.order(scheduled_at: :desc)
    end

    def show
      @stream = Stream.find(params[:id])
    end

    def new
      @stream = Stream.new
    end

    def create
      @stream = Stream.new(stream_params)
      if @stream.save
        redirect_to admin_stream_path(@stream), notice: "Stream created"
      else
        render :new
      end
    end

    def edit
      @stream = Stream.find(params[:id])
    end

    def update
      @stream = Stream.find(params[:id])
      if @stream.update(stream_params)
        redirect_to admin_stream_path(@stream), notice: "Stream updated"
      else
        render :edit
      end
    end

    def destroy
      Stream.find(params[:id]).destroy
      redirect_to admin_streams_path, notice: "Stream removed"
    end

    private

    def stream_params
      params.require(:stream).permit(:title, :description, :status, :scheduled_at, :youtube_channel_id, :visibility)
    end
  end
end
