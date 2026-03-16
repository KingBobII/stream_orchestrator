# app/controllers/users/sessions_controller.rb
module Users
  class SessionsController < Devise::SessionsController
    respond_to :json

    private

    # Called after sign in. devise-jwt will set the Authorization header with the JWT.
    def respond_with(resource, _opts = {})
      render json: {
        message: "Signed in successfully",
        user: { id: resource.id, email: resource.email, name: resource.name, role: resource.role }
      }, status: :ok
    end

    # Called after sign out. jwt token will be revoked according to revocation_requests.
    def respond_to_on_destroy
      head :no_content
    end
  end
end
