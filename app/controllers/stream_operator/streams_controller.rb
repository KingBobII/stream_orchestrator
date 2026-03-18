# module StreamOperator
#   class StreamsController < ApplicationController
#     before_action :set_stream, only: %i[show edit update destroy]

#     def index
#       channels = current_user.youtube_channels
#       @streams = Stream.where(youtube_channel: channels).order(scheduled_at: :desc).page(params[:page])
#     end

#     def show; end

#     def new
#       @stream = Stream.new
#     end

#     def create
#       @stream = Stream.new(stream_params)
#       # enforce owner-only channel assignment: only allow channels owned by current user
#       if @stream.youtube_channel_id.present?
#         ch = YoutubeChannel.find(@stream.youtube_channel_id)
#         unless ch.owner_id == current_user.id || current_user.admin?
#           return redirect_to stream_operator_streams_path, alert: "Invalid channel selection."
#         end
#       end

#       if @stream.save
#         redirect_to stream_operator_stream_path(@stream), notice: "Stream scheduled."
#       else
#         render :new, status: :unprocessable_entity
#       end
#     end

#     def edit; end

#     def update
#       if @stream.update(stream_params)
#         redirect_to stream_operator_stream_path(@stream), notice: "Stream updated."
#       else
#         render :edit, status: :unprocessable_entity
#       end
#     end

#     def destroy
#       @stream.destroy
#       redirect_to stream_operator_streams_path, notice: "Stream removed."
#     end

#     private

#     def set_stream
#       @stream = Stream.joins(:youtube_channel)
#                       .where(youtube_channel: { owner_id: current_user.id })
#                       .find(params[:id])
#     end

#     params.require(:stream).permit(
#       :title,
#       :description,
#       :status,
#       :visibility,
#       :scheduled_at,
#       :youtube_channel_id,
#       :external_video_id,
#       :thumbnails
#     )
#   end
# end
module StreamOperator
  class StreamsController < StreamOperator::BaseController
    def index
      @streams = Stream.where(youtube_channel: YoutubeChannel.owned_by(current_user))
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
        redirect_to stream_operator_stream_path(@stream), notice: "Stream scheduled"
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
        redirect_to stream_operator_stream_path(@stream), notice: "Stream updated"
      else
        render :edit
      end
    end

    def destroy
      Stream.find(params[:id]).destroy
      redirect_to stream_operator_streams_path, notice: "Stream removed"
    end

    private

    def stream_params
      params.require(:stream).permit(:title, :description, :status, :scheduled_at, :youtube_channel_id, :visibility)
    end
  end
end
