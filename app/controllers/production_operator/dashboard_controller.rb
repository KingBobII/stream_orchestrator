module ProductionOperator
  class DashboardController < ProductionOperator::BaseController
    def index
      @streams = Stream.includes(:youtube_channel).order(scheduled_at: :asc, created_at: :asc)
    end
  end
end
