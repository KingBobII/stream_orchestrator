# module ProductionOperator
#   class DashboardController < ApplicationController
#     def index
#       @scheduled_streams = Stream.where(status: "scheduled").order(scheduled_at: :asc).limit(12) if defined?(Stream)
#       @live_streams = Stream.where(status: "live").limit(8) if defined?(Stream)
#     end
#   end
# end
# module ProductionOperator
#   class DashboardController < ApplicationController
#     def index
#       @scheduled_streams = Stream.scheduled.limit(12)
#       @live_streams = Stream.live.limit(8)
#     end
#   end
# end
module ProductionOperator
  class DashboardController < ProductionOperator::BaseController
    def index
      @scheduled_streams = Stream.scheduled.limit(12)
      @live_streams = Stream.live.limit(8)
    end
  end
end
