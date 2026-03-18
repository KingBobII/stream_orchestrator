module Users
  class SessionsController < Devise::SessionsController
    respond_to :html, :json

    # HTML: use Devise default behavior (super)
    # JSON: return user info + jwt token if present
    def respond_with(resource, _opts = {})
      if request.format.json?
        user = request.env['warden'].user || resource

        unless user&.persisted?
          return render json: { error: 'Authentication failed' }, status: :unauthorized
        end

        jwt_token = request.env['warden-jwt_auth.token'] || request.env['jwt'] || nil

        render json: {
          message: 'Signed in successfully',
          user: {
            id: user.id,
            email: user.email,
            name: (user.respond_to?(:name) ? user.name : nil),
            role: (user.respond_to?(:role) ? user.role : nil),
            admin: (user.respond_to?(:admin?) ? user.admin? : false)
          },
          jwt: jwt_token
        }, status: :ok
      else
        super
      end
    end

    # ✅ FIXED METHOD SIGNATURE
    def respond_to_on_destroy(resource)
      if request.format.json?
        render json: { message: 'Logged out successfully' }, status: :ok
      else
        redirect_to new_user_session_path, notice: 'Logged out successfully'
      end
    end
  end
end
