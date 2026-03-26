# app/services/youtube/client.rb
module Youtube
  class Client
    Result = Struct.new(
      :broadcast_id,
      :stream_id,
      :video_id,
      :watch_url,
      :thumbnails,
      :status,
      :error,
      keyword_init: true
    )

    def create_broadcast(stream)
      if simulate?
        simulate_broadcast(stream)
      else
        create_real_broadcast(stream)
      end
    end

    def create_stream(stream)
      if simulate?
        simulate_stream(stream)
      else
        create_real_stream(stream)
      end
    end

    def bind_broadcast_to_stream(broadcast_id:, stream_id:)
      if simulate?
        true
      else
        bind_real_broadcast_to_stream(broadcast_id: broadcast_id, stream_id: stream_id)
      end
    end

    private

    def simulate?
      ENV["YOUTUBE_SIMULATE"].present? || Rails.env.development?
    end

    def simulate_broadcast(_stream)
      broadcast_id = "sim_broadcast_#{SecureRandom.hex(8)}"
      Result.new(
        broadcast_id: broadcast_id,
        video_id: broadcast_id,
        watch_url: "https://www.youtube.com/watch?v=#{broadcast_id}",
        thumbnails: {},
        status: "created",
        error: nil
      )
    end

    def simulate_stream(_stream)
      Result.new(
        stream_id: "sim_stream_#{SecureRandom.hex(8)}",
        status: "created",
        error: nil
      )
    end

    # Replace these with the real Google API calls when ready.
    def create_real_broadcast(_stream)
      raise NotImplementedError, "Google YouTube API broadcast creation is not wired yet."
    end

    def create_real_stream(_stream)
      raise NotImplementedError, "Google YouTube API stream creation is not wired yet."
    end

    def bind_real_broadcast_to_stream(broadcast_id:, stream_id:)
      raise NotImplementedError, "Google YouTube API broadcast/stream binding is not wired yet."
    end
  end
end
