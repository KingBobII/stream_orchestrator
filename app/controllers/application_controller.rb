class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  # Require login everywhere by default except Devise controllers
  before_action :authenticate_user!, unless: :devise_controller?
  before_action :configure_permitted_parameters, if: :devise_controller?

  # Route users after sign in based on role
  def after_sign_in_path_for(resource)
    if resource.respond_to?(:admin?) && resource.admin?
      admin_dashboard_path
    else
      youtube_channels_path
    end
  end

  private

  def authorize_admin!
    head :forbidden unless current_user&.admin?
  end

  protected

  # Permit :name on signup/profile updates. DO NOT permit :role on public sign-up
  # unless you have extra safeguards (admins setting roles).
  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: %i[name])
    devise_parameter_sanitizer.permit(:account_update, keys: %i[name])
    # If you want admins to set roles via an admin-only UI, permit :role there only.
  end
end
