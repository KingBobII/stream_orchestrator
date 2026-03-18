# module ProductionOperator
#   class StreamsController < ApplicationController
#     before_action :set_stream, only: %i[show edit update]

#     def index
#       @streams = Stream.order(scheduled_at: :asc).page(params[:page])
#     end

#     def show; end

#     def edit; end

#     def update
#       if @stream.update(stream_params)
#         redirect_to production_operator_stream_path(@stream), notice: "Stream updated."
#       else
#         render :edit, status: :unprocessable_entity
#       end
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
#
module ProductionOperator
  class StreamsController < ProductionOperator::BaseController
    def index
      @streams = Stream.live.or(Stream.upcoming)
    end

    def show
      @stream = Stream.find(params[:id])
    end

    def edit
      @stream = Stream.find(params[:id])
    end

    def update
      @stream = Stream.find(params[:id])
      if @stream.update(stream_params)
        redirect_to production_operator_stream_path(@stream), notice: "Stream updated"
      else
        render :edit
      end
    end

    private

    def stream_params
      params.require(:stream).permit(:title, :description, :status, :scheduled_at, :visibility, :youtube_channel_id)
    end
  end
end
