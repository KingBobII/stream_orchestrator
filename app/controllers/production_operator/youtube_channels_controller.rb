# module ProductionOperator
#   class YoutubeChannelsController < ApplicationController
#     def index
#       @youtube_channels = YoutubeChannel.active.order(:name).page(params[:page])
#     end

#     def show
#       @youtube_channel = YoutubeChannel.find(params[:id])
#     end
#   end
# end
module ProductionOperator
  class YoutubeChannelsController < ProductionOperator::BaseController
    def index
      @youtube_channels = YoutubeChannel.all
    end

    def show
      @youtube_channel = YoutubeChannel.find(params[:id])
    end
  end
end
