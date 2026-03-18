# # app/controllers/stream_operator/application_controller.rb
# module StreamOperator
#   class ApplicationController < ::ApplicationController
#     before_action :authenticate_user!
#     before_action :require_stream_operator!
#     layout "stream_operator"
#   end
# end
# module StreamOperator
#   class ApplicationController < ::ApplicationController
#     before_action :authenticate_user!
#     before_action :authorize_stream_operator!
#     layout "stream_operator"
#   end
# end
module StreamOperator
  class BaseController < ::ApplicationController
    layout "stream_operator"

    before_action :authenticate_user!
    before_action :authorize_stream_operator!

    private

    def authorize_stream_operator!
      redirect_to root_path, alert: "Unauthorized" unless current_user&.stream_operator?
    end
  end
end
