module Youtube
  class Client
    Result = Struct.new(
      :broadcast_id,
      :url,
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

    private

    def simulate?
      ENV["YOUTUBE_SIMULATE"].present? || Rails.env.development?
    end

    def simulate_broadcast(stream)
      broadcast_id = "sim_#{SecureRandom.hex(8)}"
      Result.new(
        broadcast_id: broadcast_id,
        url: "https://youtube.com/watch?v=#{broadcast_id}",
        status: "created",
        error: nil
      )
    end

    # Replace this with the real Google API call later.
    def create_real_broadcast(stream)
      raise NotImplementedError, "Google YouTube API integration not wired yet."
    end
  end
end
