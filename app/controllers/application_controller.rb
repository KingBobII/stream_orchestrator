class ApplicationController < ActionController::Base
  protect_from_forgery with: :null_session

  before_action :authenticate_user!

  private

  def authorize_admin!
    render json: { error: "Forbidden" }, status: :forbidden unless current_user&.admin?
  end
end
