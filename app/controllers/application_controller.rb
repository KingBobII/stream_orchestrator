class ApplicationController < ActionController::Base
  # For API-style JSON responses:
  protect_from_forgery with: :null_session

  private

  # Reads Authorization: Bearer <token>
  def authenticate_request!
    token = request.headers["Authorization"]&.split&.last
    return render json: { error: "Missing token" }, status: :unauthorized unless token

    begin
      payload = JWT.decode(token, Rails.application.credentials.secret_key_base)[0]
      @current_user = User.find(payload["user_id"])
    rescue JWT::ExpiredSignature
      render json: { error: "Token has expired" }, status: :unauthorized
    rescue JWT::DecodeError, ActiveRecord::RecordNotFound
      render json: { error: "Invalid token" }, status: :unauthorized
    end
  end

  def current_user
    @current_user
  end

  def authorize_admin!
    authenticate_request!
    render json: { error: "Forbidden" }, status: :forbidden unless current_user&.admin?
  end
end
