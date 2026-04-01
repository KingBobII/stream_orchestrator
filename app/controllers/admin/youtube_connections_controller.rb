module Admin
  class YoutubeConnectionsController < Admin::BaseController
    def connect
      state = SecureRandom.hex(32)

      session[:youtube_oauth_state] = {
        "state" => state,
        "user_id" => current_user.id
      }

      url = Youtube::OAuthService.new.authorization_url(state: state)
      redirect_to url, allow_other_host: true
    end

    def oauth_callback
      if params[:error].present?
        redirect_to admin_dashboard_path, alert: "Google authorization failed: #{params[:error]}"
        return
      end

      session_state = session.delete(:youtube_oauth_state)

      unless session_state.present? &&
             params[:state].present? &&
             params[:state] == session_state["state"]
        redirect_to admin_dashboard_path, alert: "YouTube authorization state did not match."
        return
      end

      token_data = Youtube::OAuthService.new.exchange_code!(code: params[:code])

      channel_data = Youtube::OAuthService.new.fetch_my_channel!(
        access_token: token_data["access_token"]
      )

      user = User.find(session_state["user_id"])

      channel = YoutubeChannel.find_or_initialize_by(
        external_id: channel_data.dig("id")
      )

      channel.assign_attributes(
        name: channel_data.dig("snippet", "title"),
        description: channel_data.dig("snippet", "description"),
        owner_id: user.id,
        stream_access_key: user.stream_access_key,
        oauth_access_token: token_data["access_token"],
        oauth_refresh_token: token_data["refresh_token"].presence || channel.oauth_refresh_token,
        oauth_expires_at: token_data["expires_in"].present? ? Time.current + token_data["expires_in"].to_i.seconds : channel.oauth_expires_at,
        oauth_scope: token_data["scope"],
        oauth_token_type: token_data["token_type"],
        status: "active",
        connected_at: Time.current
      )

      channel.save!

      redirect_to admin_youtube_channel_path(channel), notice: "Connected successfully."
    rescue StandardError => e
      Rails.logger.error("[Admin::YoutubeConnectionsController#oauth_callback] #{e.class}: #{e.message}")
      redirect_to admin_dashboard_path, alert: "YouTube connection failed: #{e.message}"
    end
  end
end
