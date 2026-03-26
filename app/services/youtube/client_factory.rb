require "google/apis/youtube_v3"
require "googleauth"

module Youtube
  class ClientFactory
    def self.build(youtube_channel)
      raise ArgumentError, "YoutubeChannel is missing a refresh token" if youtube_channel.oauth_refresh_token.blank?

      creds = Rails.application.credentials.fetch(:google)

      authorization = Google::Auth::UserRefreshCredentials.new(
        client_id: creds.fetch(:client_id),
        client_secret: creds.fetch(:client_secret),
        scope: Youtube::OAuthService::SCOPES,
        refresh_token: youtube_channel.oauth_refresh_token
      )

      service = Google::Apis::YoutubeV3::YouTubeService.new
      service.client_options.application_name = creds.fetch(:application_name)
      service.authorization = authorization
      service
    end
  end
end
