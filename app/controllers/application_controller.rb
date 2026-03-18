# class ApplicationController < ActionController::Base
#   protect_from_forgery with: :exception

#   # Require login everywhere by default except Devise controllers
#   before_action :authenticate_user!, unless: :devise_controller?
#   before_action :configure_permitted_parameters, if: :devise_controller?

#   # Route users after sign in based on role
#   def after_sign_in_path_for(resource)
#     return youtube_channels_path unless resource.respond_to?(:role)

#     case resource.role
#     when "admin"
#       admin_dashboard_path
#     when "stream_operator"
#       stream_operator_dashboard_path
#     when "production_operator"
#       production_operator_dashboard_path
#     else
#       youtube_channels_path
#     end
#   end

#   private

#   # Authorization helpers
#   def authorize_admin!
#     head :forbidden unless current_user&.admin?
#   end

#   def authorize_stream_operator!
#     head :forbidden unless current_user&.stream_operator? || current_user&.admin?
#   end

#   def authorize_production_operator!
#     head :forbidden unless current_user&.production_operator? || current_user&.admin?
#   end

#   protected

#   # Permit :name only (keep your security decision intact 👍)
#   def configure_permitted_parameters
#     devise_parameter_sanitizer.permit(:sign_up, keys: %i[name])
#     devise_parameter_sanitizer.permit(:account_update, keys: %i[name])
#   end
# end

class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  before_action :authenticate_user!, unless: :devise_controller?
  before_action :configure_permitted_parameters, if: :devise_controller?

  def after_sign_in_path_for(resource)
    return youtube_channels_path unless resource.respond_to?(:role)

    case resource.role
    when "admin"
      admin_dashboard_path
    when "stream_operator"
      stream_operator_dashboard_path
    when "production_operator"
      production_operator_dashboard_path
    else
      youtube_channels_path
    end
  end

  private

  def authorize_admin!
    head :forbidden unless current_user&.admin?
  end

  def authorize_stream_operator!
    head :forbidden unless current_user&.stream_operator? || current_user&.admin?
  end

  def authorize_production_operator!
    head :forbidden unless current_user&.production_operator? || current_user&.admin?
  end

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: %i[name])
    devise_parameter_sanitizer.permit(:account_update, keys: %i[name])
  end
end
