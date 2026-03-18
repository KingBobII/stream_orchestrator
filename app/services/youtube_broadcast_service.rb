# app/services/youtube_broadcast_service.rb
class YoutubeBroadcastService
  def initialize(stream)
    @stream = stream
    # initialize API client here (e.g. google-api-client)
  end

  # schedule! should be idempotent: if a broadcast already exists, return its id.
  # Returns a hash like: { external_id: "abc123", thumbnails: { "high" => {"url" => "..."}, ... } }
  def schedule!
    # TODO: implement actual YouTube call
    # Example pseudocode:
    # if @stream.external_video_id.present?
    #   return { external_id: @stream.external_video_id, thumbnails: existing_thumbs }
    # end
    #
    # call YouTube API to create broadcast, or create & bind stream,
    # return external id and thumbnails.

    # Temporary stub response to help local testing (remove in prod)
    {
      external_id: nil,
      thumbnails: @stream.thumbnails
    }
  end
end
