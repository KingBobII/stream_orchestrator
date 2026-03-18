# module ProductionOperator
#   class ApplicationController < ::ApplicationController
#     before_action :authenticate_user!
#     before_action :authorize_production_operator!
#     layout "production_operator"
#   end
# end
module ProductionOperator
  class BaseController < ::ApplicationController
    layout "production_operator"

    before_action :authenticate_user!
    before_action :authorize_production_operator!

    private

    def authorize_production_operator!
      redirect_to root_path, alert: "Unauthorized" unless current_user&.production_operator?
    end
  end
end
