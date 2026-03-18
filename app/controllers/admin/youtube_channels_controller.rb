# module Admin
#   class YoutubeChannelsController < Admin::ApplicationController
#     before_action :set_youtube_channel, only: %i[show edit update destroy sync]

#     def index
#       @youtube_channels = YoutubeChannel.order(created_at: :desc).page(params[:page])
#     end

#     def show; end

#     def new
#       @youtube_channel = YoutubeChannel.new
#     end

#     def create
#       @youtube_channel = YoutubeChannel.new(youtube_channel_params)
#       if @youtube_channel.save
#         redirect_to admin_youtube_channel_path(@youtube_channel), notice: "Channel created."
#       else
#         render :new, status: :unprocessable_entity
#       end
#     end

#     def edit; end

#     def update
#       if @youtube_channel.update(youtube_channel_params)
#         redirect_to admin_youtube_channel_path(@youtube_channel), notice: "Channel updated."
#       else
#         render :edit, status: :unprocessable_entity
#       end
#     end

#     def destroy
#       @youtube_channel.destroy
#       redirect_to admin_youtube_channels_path, notice: "Channel removed."
#     end

#     def sync
#       YoutubeChannelSyncService.new(@youtube_channel).enqueue_metadata_sync
#       redirect_to admin_youtube_channel_path(@youtube_channel), notice: "Sync enqueued."
#     end

#     private

#     def set_youtube_channel
#       @youtube_channel = YoutubeChannel.find(params[:id])
#     end

#     def youtube_channel_params
#       permitted = %i[name description external_id status published_at settings]
#       permitted << :owner_id if current_user&.admin?
#       params.require(:youtube_channel).permit(permitted)
#     end
#   end
# end
#
module Admin
  class YoutubeChannelsController < Admin::BaseController
    def index
      @youtube_channels = YoutubeChannel.all
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
        render :new
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
        render :edit
      end
    end

    def destroy
      YoutubeChannel.find(params[:id]).destroy
      redirect_to admin_youtube_channels_path, notice: "Channel removed"
    end

    def sync
      @youtube_channel = YoutubeChannel.find(params[:id])
      # call your sync service here, e.g. YoutubeChannelSyncService.new(@youtube_channel).perform
      redirect_to admin_youtube_channel_path(@youtube_channel), notice: "Sync enqueued"
    end

    private

    def youtube_channel_params
      params.require(:youtube_channel).permit(:name, :external_id, :owner_id)
    end
  end
end
