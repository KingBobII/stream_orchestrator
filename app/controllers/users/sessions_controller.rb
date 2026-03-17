# app/controllers/users/sessions_controller.rb
module Users
  class SessionsController < Devise::SessionsController
    respond_to :json

    private

    # Devise may call respond_with in contexts where `resource` or `current_user`
    # are not reliably populated. Use Warden which holds the authenticated user.
    def respond_with(_resource, _opts = {})
      # Prefer warden user (guaranteed to be the logged-in user after sign-in)
      user = request.env['warden'].user || current_user

      unless user && user.persisted?
        # Fallback safe error response — shouldn't happen on a successful sign-in
        return render json: { error: 'Authentication failed' }, status: :unauthorized
      end

      render json: {
        message: 'Signed in successfully',
        user: {
          id: user.id,
          email: user.email,
          name: user.name,
          role: user.role
        }
      }, status: :ok
    end

    # Called on sign out. devise-jwt revokes the token according to config.
    def respond_to_on_destroy
      render json: { message: 'Logged out successfully' }, status: :ok
    end
  end
end
