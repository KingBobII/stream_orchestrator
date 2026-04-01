module StreamOperator
  class BaseController < ApplicationController
    layout "stream_operator"

    before_action :authenticate_user!
    before_action :ensure_stream_operator!

    private

    def ensure_stream_operator!
      return if current_user&.stream_operator?

      redirect_to root_path, alert: "You are not authorized to access that page."
    end
  end
end
