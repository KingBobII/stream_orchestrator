# # app/controllers/admin/application_controller.rb
# module Admin
#   class ApplicationController < ::ApplicationController
#     before_action :authenticate_user!
#     before_action :require_admin!
#     layout "admin"
#   end
# end

# module Admin
#   class ApplicationController < ::ApplicationController
#     before_action :authenticate_user!
#     before_action :authorize_admin!
#     layout "admin"
#   end
# end

module Admin
  class BaseController < ::ApplicationController
    layout "admin"

    before_action :authenticate_user!
    before_action :authorize_admin!

    private

    def authorize_admin!
      # keep your existing authorization logic here, e.g.
      redirect_to root_path, alert: "Unauthorized" unless current_user&.admin?
    end
  end
end
