# module Admin
#   class DashboardController < ApplicationController
#     def index
#       @recent_users = User.order(created_at: :desc).limit(8)
#       @recent_channels = YoutubeChannel.order(created_at: :desc).limit(8)
#       @upcoming_streams = Stream.upcoming.limit(8) if defined?(Stream)
#     end
#   end
# end
# module Admin
#   class DashboardController < ApplicationController
#     def index
#       @recent_users = User.order(created_at: :desc).limit(8)
#       @recent_channels = YoutubeChannel.order(created_at: :desc).limit(8)
#       @upcoming_streams = Stream.upcoming.limit(8)
#     end
#   end
# end
module Admin
  class DashboardController < Admin::BaseController
    def index
      @recent_users = User.order(created_at: :desc).limit(8)
      @recent_channels = YoutubeChannel.includes(:owner).order(created_at: :desc).limit(8)
      @upcoming_streams = Stream.includes(:youtube_channel).upcoming.limit(8)
    end
  end
end
