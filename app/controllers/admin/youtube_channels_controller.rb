module Admin
  class YoutubeChannelsController < Admin::BaseController
    def index
      @youtube_channels = YoutubeChannel.order(:name)
    end

    def show
      @youtube_channel = YoutubeChannel.find(params[:id])
    end

    def new
      @youtube_channel = YoutubeChannel.new
    end

    def create
      @youtube_channel = YoutubeChannel.new(youtube_channel_params)

      if @youtube_channel.save
        redirect_to admin_youtube_channel_path(@youtube_channel), notice: "Channel created"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      @youtube_channel = YoutubeChannel.find(params[:id])
    end

    def update
      @youtube_channel = YoutubeChannel.find(params[:id])

      if @youtube_channel.update(youtube_channel_params)
        redirect_to admin_youtube_channel_path(@youtube_channel), notice: "Channel updated"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      YoutubeChannel.find(params[:id]).destroy
      redirect_to admin_youtube_channels_path, notice: "Channel removed"
    end

    def sync
      @youtube_channel = YoutubeChannel.find(params[:id])
      Youtube::SyncChannelMetadataJob.perform_later(@youtube_channel.id)
      redirect_to admin_youtube_channel_path(@youtube_channel), notice: "Sync enqueued"
    end

    def connect
      @youtube_channel = YoutubeChannel.find(params[:id])

      state = SecureRandom.hex(32)
      session[:youtube_oauth_state] = {
        state: state,
        youtube_channel_id: @youtube_channel.id
      }

      url = Youtube::OAuthService.new(@youtube_channel).authorization_url(state: state)
      redirect_to url, allow_other_host: true
    end

    def oauth_callback
      session_state = session.delete(:youtube_oauth_state)

      unless session_state.present? &&
             params[:state].present? &&
             params[:state] == session_state["state"]
        redirect_to admin_youtube_channels_path, alert: "YouTube authorization state did not match."
        return
      end

      youtube_channel = YoutubeChannel.find(session_state["youtube_channel_id"])
      token_data = Youtube::OAuthService.new(youtube_channel).exchange_code!(code: params[:code])

      youtube_channel.update!(
        oauth_access_token: token_data["access_token"],
        oauth_refresh_token: token_data["refresh_token"].presence || youtube_channel.oauth_refresh_token,
        oauth_expires_at: token_data["expires_in"].present? ? Time.current + token_data["expires_in"].to_i.seconds : youtube_channel.oauth_expires_at,
        oauth_scope: token_data["scope"],
        oauth_token_type: token_data["token_type"],
        status: "active"
      )

      redirect_to admin_youtube_channel_path(youtube_channel), notice: "YouTube channel connected."
    rescue StandardError => e
      Rails.logger.error("[Admin::YoutubeChannelsController#oauth_callback] #{e.class}: #{e.message}")
      redirect_to admin_youtube_channels_path, alert: "YouTube authorization failed: #{e.message}"
    end

    def disconnect
      @youtube_channel = YoutubeChannel.find(params[:id])
      @youtube_channel.update!(
        oauth_access_token: nil,
        oauth_refresh_token: nil,
        oauth_expires_at: nil,
        oauth_scope: nil,
        oauth_token_type: nil,
        status: "inactive"
      )
      redirect_to admin_youtube_channel_path(@youtube_channel), notice: "YouTube channel disconnected."
    end

    private

    def youtube_channel_params
      params.require(:youtube_channel).permit(:name, :external_id, :owner_id, :description)
    end
  end
end
