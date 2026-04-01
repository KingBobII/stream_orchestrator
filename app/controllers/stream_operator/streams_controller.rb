module StreamOperator
  class StreamsController < StreamOperator::BaseController
    before_action :set_stream, only: %i[show]

    def index
      @youtube_channels = YoutubeChannel.visible_to(current_user).order(:name)
      @streams = Stream.includes(:youtube_channel)
                       .visible_to(current_user)
                       .order(scheduled_at: :asc, created_at: :asc)
                       .page(params[:page])
                       .per(params[:per_page] || 15)
    end

    def show; end

    private

    def set_stream
      @stream = Stream.visible_to(current_user).find(params[:id])
    end
  end
end
