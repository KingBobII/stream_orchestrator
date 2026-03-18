# module StreamOperator
#   class YoutubeChannelsController < ApplicationController
#     before_action :set_youtube_channel, only: %i[show edit update destroy]

#     def index
#       @youtube_channels = current_user.youtube_channels.order(created_at: :desc).page(params[:page])
#     end

#     def show; end

#     def new
#       @youtube_channel = current_user.youtube_channels.new
#     end

#     def create
#       @youtube_channel = current_user.youtube_channels.new(youtube_channel_params)
#       @youtube_channel.owner = current_user
#       if @youtube_channel.save
#         redirect_to stream_operator_youtube_channel_path(@youtube_channel), notice: "Channel created."
#       else
#         render :new, status: :unprocessable_entity
#       end
#     end

#     def edit; end

#     def update
#       if @youtube_channel.update(youtube_channel_params)
#         redirect_to stream_operator_youtube_channel_path(@youtube_channel), notice: "Channel updated."
#       else
#         render :edit, status: :unprocessable_entity
#       end
#     end

#     def destroy
#       @youtube_channel.destroy
#       redirect_to stream_operator_youtube_channels_path, notice: "Channel removed."
#     end

#     private

#     def set_youtube_channel
#       @youtube_channel = current_user.youtube_channels.find(params[:id])
#     end

#     def youtube_channel_params
#       params.require(:youtube_channel).permit(:name, :description, :external_id, :status, :published_at, :settings)
#     end
#   end
# end
module StreamOperator
  class YoutubeChannelsController < StreamOperator::BaseController
    def index
      @youtube_channels = YoutubeChannel.owned_by(current_user)
    end

    def show
      @youtube_channel = YoutubeChannel.find(params[:id])
    end

    def new
      @youtube_channel = YoutubeChannel.new
    end

    def create
      @youtube_channel = YoutubeChannel.new(youtube_channel_params.merge(owner: current_user))
      if @youtube_channel.save
        redirect_to stream_operator_youtube_channel_path(@youtube_channel), notice: "Channel created"
      else
        render :new
      end
    end

    def edit
      @youtube_channel = YoutubeChannel.find(params[:id])
    end

    def update
      @youtube_channel = YoutubeChannel.find(params[:id])
      if @youtube_channel.update(youtube_channel_params)
        redirect_to stream_operator_youtube_channel_path(@youtube_channel), notice: "Channel updated"
      else
        render :edit
      end
    end

    def destroy
      YoutubeChannel.find(params[:id]).destroy
      redirect_to stream_operator_youtube_channels_path, notice: "Channel removed"
    end

    private

    def youtube_channel_params
      params.require(:youtube_channel).permit(:name, :external_id)
    end
  end
end
