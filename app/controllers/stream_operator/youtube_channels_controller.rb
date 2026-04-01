module StreamOperator
  class YoutubeChannelsController < StreamOperator::BaseController
    def index
      @youtube_channels = YoutubeChannel.visible_to(current_user).order(:name)
    end

    def show
      @youtube_channel = YoutubeChannel.visible_to(current_user).find(params[:id])
    end
  end
end
