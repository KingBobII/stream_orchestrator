module Admin
  class YoutubeChannelsController < Admin::BaseController
    before_action :set_youtube_channel, only: %i[show edit update destroy sync disconnect]

    def index
      @youtube_channels = YoutubeChannel.order(:name)
    end

    def show; end

    def new
      @youtube_channel = YoutubeChannel.new
    end

    def create
      @youtube_channel = YoutubeChannel.new(
        youtube_channel_params.merge(
          owner: current_user,
          stream_access_key: current_user.stream_access_key,
          status: youtube_channel_params[:status].presence || "active"
        )
      )

      if @youtube_channel.save
        redirect_to admin_youtube_channel_path(@youtube_channel), notice: "Channel created"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @youtube_channel.update(youtube_channel_params)
        redirect_to admin_youtube_channel_path(@youtube_channel), notice: "Channel updated"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @youtube_channel.destroy
      redirect_to admin_youtube_channels_path, notice: "Channel removed"
    end

    def sync
      unless @youtube_channel.connected?
        redirect_to admin_youtube_channel_path(@youtube_channel), alert: "Connect the channel first."
        return
      end

      Youtube::SyncChannelMetadataJob.perform_later(@youtube_channel.id)
      redirect_to admin_youtube_channel_path(@youtube_channel), notice: "Sync enqueued"
    end

    def disconnect
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

    def set_youtube_channel
      @youtube_channel = YoutubeChannel.find(params[:id])
    end

    def youtube_channel_params
      params.require(:youtube_channel).permit(:name, :external_id, :description, :status)
    end
  end
end
