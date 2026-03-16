class SessionsController < ApplicationController
  # POST /login
  def create
    user = User.find_by(email: params[:email]&.downcase)

    if user&.authenticate(params[:password])
      token = user.generate_jwt
      render json: { token: token, user: { id: user.id, email: user.email, name: user.name, role: user.role } }, status: :ok
    else
      render json: { error: "Invalid email or password" }, status: :unauthorized
    end
  end
end
