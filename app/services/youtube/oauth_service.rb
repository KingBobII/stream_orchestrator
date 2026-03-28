# require "net/http"
# require "uri"
# require "json"

# module Youtube
#   class OAuthService
#     AUTH_URL = "https://accounts.google.com/o/oauth2/v2/auth".freeze
#     TOKEN_URL = URI("https://oauth2.googleapis.com/token").freeze

#     SCOPES = [
#       "https://www.googleapis.com/auth/youtube.force-ssl"
#     ].freeze

#     def initialize(youtube_channel)
#       @youtube_channel = youtube_channel
#     end

#     def authorization_url(state:)
#       uri = URI(AUTH_URL)
#       uri.query = URI.encode_www_form(
#         client_id: client_id,
#         redirect_uri: redirect_uri,
#         response_type: "code",
#         scope: SCOPES.join(" "),
#         access_type: "offline",
#         prompt: "consent",
#         include_granted_scopes: "true",
#         state: state
#       )
#       uri.to_s
#     end

#     def exchange_code!(code:)
#       response = Net::HTTP.start(TOKEN_URL.host, TOKEN_URL.port, use_ssl: true) do |http|
#         request = Net::HTTP::Post.new(TOKEN_URL)
#         request.set_form_data(
#           code: code,
#           client_id: client_id,
#           client_secret: client_secret,
#           redirect_uri: redirect_uri,
#           grant_type: "authorization_code"
#         )
#         http.request(request)
#       end

#       payload = JSON.parse(response.body)

#       unless response.is_a?(Net::HTTPSuccess)
#         raise StandardError, payload["error_description"] || payload["error"] || "OAuth exchange failed"
#       end

#       payload
#     end

#     private

#     attr_reader :youtube_channel

#     def google_credentials
#       Rails.application.credentials.fetch(:google)
#     end

#     def client_id
#       google_credentials.fetch(:client_id)
#     end

#     def client_secret
#       google_credentials.fetch(:client_secret)
#     end

#     def redirect_uri
#       google_credentials.fetch(:redirect_uri)
#     end
#   end
# end# app/services/youtube/oauth_service.rb
require "net/http"
require "uri"
require "json"

module Youtube
  class OAuthService
    AUTH_URL = "https://accounts.google.com/o/oauth2/v2/auth".freeze
    TOKEN_URL = URI("https://oauth2.googleapis.com/token").freeze
    CHANNELS_URL = URI("https://www.googleapis.com/youtube/v3/channels").freeze

    SCOPES = [
      "https://www.googleapis.com/auth/youtube.force-ssl"
    ].freeze

    def authorization_url(state:)
      uri = URI(AUTH_URL)
      uri.query = URI.encode_www_form(
        client_id: client_id,
        redirect_uri: redirect_uri,
        response_type: "code",
        scope: SCOPES.join(" "),
        access_type: "offline",
        prompt: "consent",
        include_granted_scopes: "true",
        state: state
      )
      uri.to_s
    end

    def exchange_code!(code:)
      response = Net::HTTP.start(TOKEN_URL.host, TOKEN_URL.port, use_ssl: true) do |http|
        request = Net::HTTP::Post.new(TOKEN_URL)
        request.set_form_data(
          code: code,
          client_id: client_id,
          client_secret: client_secret,
          redirect_uri: redirect_uri,
          grant_type: "authorization_code"
        )
        http.request(request)
      end

      payload = JSON.parse(response.body)

      unless response.is_a?(Net::HTTPSuccess)
        raise StandardError, payload["error_description"] || payload["error"] || "OAuth exchange failed"
      end

      payload
    end

    def fetch_my_channel!(access_token:)
      uri = URI(CHANNELS_URL.to_s)
      uri.query = URI.encode_www_form(
        part: "snippet",
        mine: "true"
      )

      response = Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
        request = Net::HTTP::Get.new(uri)
        request["Authorization"] = "Bearer #{access_token}"
        http.request(request)
      end

      payload = JSON.parse(response.body)

      unless response.is_a?(Net::HTTPSuccess)
        message = payload.dig("error", "message") || payload["error_description"] || "Failed to fetch YouTube channel"
        raise StandardError, message
      end

      channel = payload["items"]&.first
      raise StandardError, "No YouTube channel found for this Google account" if channel.nil?

      channel
    end

    private

    def google_credentials
      Rails.application.credentials.fetch(:google)
    end

    def client_id
      google_credentials.fetch(:client_id)
    end

    def client_secret
      google_credentials.fetch(:client_secret)
    end

    def redirect_uri
      google_credentials.fetch(:redirect_uri)
    end
  end
end
