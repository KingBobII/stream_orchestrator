# module ProductionOperator
#   class StreamsController < ProductionOperator::BaseController
#     def index
#       @streams = Stream.live.or(Stream.upcoming)
#     end

#     def show
#       @stream = Stream.find(params[:id])
#     end

#     def edit
#       @stream = Stream.find(params[:id])
#     end

#     def update
#       @stream = Stream.find(params[:id])
#       if @stream.update(stream_params)
#         redirect_to production_operator_stream_path(@stream), notice: "Stream updated"
#       else
#         render :edit
#       end
#     end

#     private

#     def stream_params
#       params.require(:stream).permit(:title, :description, :status, :scheduled_at, :visibility, :youtube_channel_id)
#     end
#   end
# end
# app/controllers/production_operator/streams_controller.rb
# app/controllers/production_operator/streams_controller.rb
module ProductionOperator
  class StreamsController < ProductionOperator::BaseController
    before_action :set_stream, only: %i[show edit update]

    def index
      @live_streams = Stream.live.order(updated_at: :desc).limit(8)
      @upcoming_streams = Stream.upcoming.page(params[:page]).per(params[:per_page] || 12)
    end

    def show; end

    def edit; end

    def update
      if @stream.update(stream_params)
        redirect_to production_operator_stream_path(@stream), notice: "Stream updated"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_stream
      @stream = Stream.find(params[:id])
    end

    def stream_params
      params.require(:stream).permit(:status, :visibility, :scheduled_at)
    end
  end
end
