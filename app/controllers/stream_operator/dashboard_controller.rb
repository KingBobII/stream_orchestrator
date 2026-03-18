# # app/controllers/stream_operator/dashboard_controller.rb
# module StreamOperator
#   class DashboardController < ApplicationController
#     def index
#       @my_channels = YoutubeChannel.where(owner_id: current_user.id)
#       @upcoming_streams = Stream.where(youtube_channel: @my_channels).upcoming.limit(8) if defined?(Stream)
#     end
#   end
# end
# module StreamOperator
#   class DashboardController < ApplicationController
#     def index
#       @my_channels = YoutubeChannel.owned_by(current_user)
#       @upcoming_streams = Stream.where(youtube_channel: @my_channels).upcoming.limit(8)
#     end
#   end
# end
module StreamOperator
  class DashboardController < StreamOperator::BaseController
    def index
      @my_channels = YoutubeChannel.owned_by(current_user)
      @upcoming_streams = Stream.where(youtube_channel: @my_channels).upcoming.limit(8)
    end
  end
end
