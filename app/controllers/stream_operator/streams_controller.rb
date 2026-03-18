# module StreamOperator
#   class StreamsController < StreamOperator::BaseController
#     def index
#       @streams = Stream.where(youtube_channel: YoutubeChannel.owned_by(current_user))
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
#         redirect_to stream_operator_stream_path(@stream), notice: "Stream scheduled"
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
#         redirect_to stream_operator_stream_path(@stream), notice: "Stream updated"
#       else
#         render :edit
#       end
#     end

#     def destroy
#       Stream.find(params[:id]).destroy
#       redirect_to stream_operator_streams_path, notice: "Stream removed"
#     end

#     private

#     def stream_params
#       params.require(:stream).permit(:title, :description, :status, :scheduled_at, :youtube_channel_id, :visibility)
#     end
#   end
# end
# app/controllers/stream_operator/streams_controller.rb
# app/controllers/stream_operator/streams_controller.rb
module StreamOperator
  class StreamsController < StreamOperator::BaseController
    before_action :set_stream, only: %i[show edit update destroy]

    def index
      @streams = Stream.includes(:youtube_channel)
                       .where(youtube_channel: YoutubeChannel.owned_by(current_user))
                       .order(scheduled_at: :asc)
                       .page(params[:page])
                       .per(params[:per_page] || 15)
    end

    def show; end

    def new
      @stream = Stream.new
    end

    def create
      @stream = Stream.new(stream_params)
      if @stream.save
        redirect_to stream_operator_stream_path(@stream), notice: "Stream scheduled"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @stream.update(stream_params)
        redirect_to stream_operator_stream_path(@stream), notice: "Stream updated"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @stream.destroy
      redirect_to stream_operator_streams_path, notice: "Stream removed"
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
