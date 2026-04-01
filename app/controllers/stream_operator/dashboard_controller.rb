module StreamOperator
  class DashboardController < StreamOperator::BaseController
    def index
      @youtube_channels = YoutubeChannel.visible_to(current_user).order(:name)
      @streams = Stream.includes(:youtube_channel)
                       .visible_to(current_user)
                       .upcoming
                       .order(scheduled_at: :asc)
                       .limit(8)
    end
  end
end
