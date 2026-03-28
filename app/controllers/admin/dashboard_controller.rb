module Admin
  class DashboardController < Admin::BaseController
    def index
      @recent_users = User.order(created_at: :desc).limit(8)
      @recent_channels = YoutubeChannel.includes(:owner).order(created_at: :desc).limit(8)
      @connected_channels = YoutubeChannel.available_for_streams.limit(8)
      @upcoming_streams = Stream.includes(:youtube_channel).upcoming.limit(8)
    end
  end
end
