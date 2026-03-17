module Admin
  class DashboardController < ApplicationController
    before_action :authorize_admin!

    def index
      # Add admin dashboard logic here
    end
  end
end
