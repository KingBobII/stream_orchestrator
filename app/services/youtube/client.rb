# require "uri"
# require "json"
# require "ostruct"

# module Youtube
#   class Client
#     BASE_URL = "https://www.googleapis.com/youtube/v3".freeze

#     GoogleApiError = Class.new(StandardError)

#     attr_reader :youtube_channel

#     def initialize(youtube_channel)
#       @youtube_channel = youtube_channel
#     end

#     def fetch_my_channels!
#       request(
#         :get,
#         "/channels",
#         params: {
#           part: "snippet,contentDetails,statistics,status",
#           mine: true,
#           maxResults: 50
#         }
#       )
#     end

#     def fetch_my_channel!
#       fetch_my_channels!
#     end

#     def create_broadcast(stream)
#       request(
#         :post,
#         "/liveBroadcasts",
#         params: { part: "snippet,status,contentDetails" },
#         body: {
#           snippet: {
#             title: stream.title,
#             description: stream.description.to_s,
#             scheduledStartTime: stream.scheduled_at.utc.iso8601
#           },
#           status: {
#             privacyStatus: stream.visibility,
#             selfDeclaredMadeForKids: false
#           },
#           contentDetails: {
#             enableAutoStart: false,
#             enableAutoStop: false,
#             monitorStream: {
#               enableMonitorStream: false
#             }
#           }
#         }
#       )
#     end

#     def update_broadcast(stream)
#       request(
#         :put,
#         "/liveBroadcasts",
#         params: { part: "snippet,status,contentDetails" },
#         body: {
#           id: stream.youtube_broadcast_id,
#           snippet: {
#             title: stream.title,
#             description: stream.description.to_s,
#             scheduledStartTime: stream.scheduled_at.utc.iso8601
#           },
#           status: {
#             privacyStatus: stream.visibility,
#             selfDeclaredMadeForKids: false
#           },
#           contentDetails: {
#             enableAutoStart: false,
#             enableAutoStop: false,
#             monitorStream: {
#               enableMonitorStream: false
#             }
#           }
#         }
#       )
#     end

#     def create_stream(stream)
#       response = request(
#         :post,
#         "/liveStreams",
#         params: { part: "snippet,cdn,contentDetails" },
#         body: {
#           snippet: {
#             title: "#{stream.title} stream",
#             description: stream.description.to_s
#           },
#           cdn: {
#             ingestionType: "rtmp",
#             resolution: "variable",
#             frameRate: "variable"
#           },
#           contentDetails: {
#             isReusable: true
#           }
#         }
#       )

#       ingestion_info = response.dig("cdn", "ingestionInfo") || {}

#       OpenStruct.new(
#         stream_id: response["id"],
#         ingestion_address: ingestion_info["ingestionAddress"],
#         stream_name: ingestion_info["streamName"]
#       )
#     end

#     def bind_broadcast_to_stream(broadcast_id:, stream_id:)
#       request(
#         :post,
#         "/liveBroadcasts/bind",
#         params: {
#           id: broadcast_id,
#           streamId: stream_id,
#           part: "id,snippet,contentDetails,status"
#         }
#       )
#     end

#     def refresh_access_token!(refresh_token:)
#       response = Net::HTTP.start(TOKEN_URL.host, TOKEN_URL.port, use_ssl: true) do |http|
#         request = Net::HTTP::Post.new(TOKEN_URL)
#         request.set_form_data(
#           refresh_token: refresh_token,
#           client_id: client_id,
#           client_secret: client_secret,
#           grant_type: "refresh_token"
#         )
#         http.request(request)
#       end

#       payload = JSON.parse(response.body)

#       unless response.is_a?(Net::HTTPSuccess)
#         raise GoogleApiError, payload["error_description"] || payload["error"] || "Token refresh failed"
#       end

#       payload
#     end

#     private

#     TOKEN_URL = URI("https://oauth2.googleapis.com/token").freeze

#     def request(method, path, params: {}, body: nil)
#       uri = URI("#{BASE_URL}#{path}")
#       uri.query = URI.encode_www_form(params.compact) if params.present?

#       response = perform_request(method, uri, body: body)
#       parsed = response.body.present? ? JSON.parse(response.body) : {}

#       unless response.is_a?(Net::HTTPSuccess)
#         message =
#           parsed.dig("error", "message") ||
#           parsed["error_description"] ||
#           parsed["error"] ||
#           "YouTube API request failed"

#         raise GoogleApiError, message
#       end

#       parsed
#     end

#     def perform_request(method, uri, body: nil)
#       request = build_request(method, uri)
#       request["Authorization"] = "Bearer #{access_token!}"
#       request["Content-Type"] = "application/json"
#       request.body = body.to_json if body.present?

#       Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
#         http.request(request)
#       end
#     end

#     def build_request(method, uri)
#       case method
#       when :get then Net::HTTP::Get.new(uri.request_uri)
#       when :post then Net::HTTP::Post.new(uri.request_uri)
#       when :put then Net::HTTP::Put.new(uri.request_uri)
#       when :delete then Net::HTTP::Delete.new(uri.request_uri)
#       else
#         raise ArgumentError, "Unsupported HTTP method: #{method}"
#       end
#     end

#     def access_token!
#       return youtube_channel.oauth_access_token if youtube_channel.oauth_access_token.present? && !youtube_channel.oauth_expired?

#       raise GoogleApiError, "Missing refresh token" if youtube_channel.oauth_refresh_token.blank?

#       token_data = refresh_access_token!(refresh_token: youtube_channel.oauth_refresh_token)

#       expires_at =
#         if token_data["expires_in"].present?
#           Time.current + token_data["expires_in"].to_i.seconds
#         else
#           youtube_channel.oauth_expires_at
#         end

#       youtube_channel.update!(
#         oauth_access_token: token_data["access_token"],
#         oauth_refresh_token: token_data["refresh_token"].presence || youtube_channel.oauth_refresh_token,
#         oauth_expires_at: expires_at,
#         oauth_scope: token_data["scope"].presence || youtube_channel.oauth_scope,
#         oauth_token_type: token_data["token_type"].presence || youtube_channel.oauth_token_type
#       )

#       youtube_channel.oauth_access_token
#     end

#     def client_id
#       google_credentials.fetch(:client_id)
#     end

#     def client_secret
#       google_credentials.fetch(:client_secret)
#     end

#     def google_credentials
#       Rails.application.credentials.fetch(:google)
#     end
#   end
# end
require "net/http"
require "uri"
require "json"
require "ostruct"

module Youtube
  class Client
    BASE_URL = "https://www.googleapis.com/youtube/v3".freeze
    TOKEN_URL = URI("https://oauth2.googleapis.com/token").freeze

    GoogleApiError = Class.new(StandardError)

    attr_reader :youtube_channel

    def initialize(youtube_channel)
      @youtube_channel = youtube_channel
    end

    def fetch_my_channels!
      request(
        :get,
        "/channels",
        params: {
          part: "snippet,contentDetails,statistics,status",
          mine: true,
          maxResults: 50
        }
      )
    end

    def fetch_my_channel!
      fetch_my_channels!
    end

    def create_broadcast(stream)
      request(
        :post,
        "/liveBroadcasts",
        params: { part: "snippet,status,contentDetails" },
        body: {
          snippet: {
            title: stream.title,
            description: stream.description.to_s,
            scheduledStartTime: stream.scheduled_at.utc.iso8601
          },
          status: {
            privacyStatus: stream.visibility,
            selfDeclaredMadeForKids: false
          },
          contentDetails: {
            enableAutoStart: false,
            enableAutoStop: false,
            monitorStream: {
              enableMonitorStream: false
            }
          }
        }
      )
    end

    def update_broadcast(stream)
      request(
        :put,
        "/liveBroadcasts",
        params: { part: "snippet,status,contentDetails" },
        body: {
          id: stream.youtube_broadcast_id,
          snippet: {
            title: stream.title,
            description: stream.description.to_s,
            scheduledStartTime: stream.scheduled_at.utc.iso8601
          },
          status: {
            privacyStatus: stream.visibility,
            selfDeclaredMadeForKids: false
          },
          contentDetails: {
            enableAutoStart: false,
            enableAutoStop: false,
            monitorStream: {
              enableMonitorStream: false
            }
          }
        }
      )
    end

    def create_stream(stream)
      response = request(
        :post,
        "/liveStreams",
        params: { part: "snippet,cdn,contentDetails" },
        body: {
          snippet: {
            title: "#{stream.title} stream",
            description: stream.description.to_s
          },
          cdn: {
            ingestionType: "rtmp",
            resolution: "variable",
            frameRate: "variable"
          },
          contentDetails: {
            isReusable: true
          }
        }
      )

      ingestion_info = response.dig("cdn", "ingestionInfo") || {}

      OpenStruct.new(
        stream_id: response["id"],
        ingestion_address: ingestion_info["ingestionAddress"],
        stream_name: ingestion_info["streamName"]
      )
    end

    def bind_broadcast_to_stream(broadcast_id:, stream_id:)
      request(
        :post,
        "/liveBroadcasts/bind",
        params: {
          id: broadcast_id,
          streamId: stream_id,
          part: "id,snippet,contentDetails,status"
        }
      )
    end

    def refresh_access_token!(refresh_token:)
      response = Net::HTTP.start(TOKEN_URL.host, TOKEN_URL.port, use_ssl: true) do |http|
        request = Net::HTTP::Post.new(TOKEN_URL)
        request.set_form_data(
          refresh_token: refresh_token,
          client_id: client_id,
          client_secret: client_secret,
          grant_type: "refresh_token"
        )
        http.request(request)
      end

      payload = JSON.parse(response.body)

      unless response.is_a?(Net::HTTPSuccess)
        raise GoogleApiError, payload["error_description"] || payload["error"] || "Token refresh failed"
      end

      payload
    end

    private

    def request(method, path, params: {}, body: nil)
      uri = URI("#{BASE_URL}#{path}")
      uri.query = URI.encode_www_form(params.compact) if params.present?

      response = perform_request(method, uri, body: body)
      parsed = response.body.present? ? JSON.parse(response.body) : {}

      unless response.is_a?(Net::HTTPSuccess)
        message =
          parsed.dig("error", "message") ||
          parsed["error_description"] ||
          parsed["error"] ||
          "YouTube API request failed"

        raise GoogleApiError, message
      end

      parsed
    end

    def perform_request(method, uri, body: nil)
      request = build_request(method, uri)
      request["Authorization"] = "Bearer #{access_token!}"
      request["Content-Type"] = "application/json"
      request.body = body.to_json if body.present?

      Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
        http.request(request)
      end
    end

    def build_request(method, uri)
      case method
      when :get then Net::HTTP::Get.new(uri.request_uri)
      when :post then Net::HTTP::Post.new(uri.request_uri)
      when :put then Net::HTTP::Put.new(uri.request_uri)
      when :delete then Net::HTTP::Delete.new(uri.request_uri)
      else
        raise ArgumentError, "Unsupported HTTP method: #{method}"
      end
    end

    def access_token!
      return youtube_channel.oauth_access_token if youtube_channel.oauth_access_token.present? && !youtube_channel.oauth_expired?

      raise GoogleApiError, "Missing refresh token" if youtube_channel.oauth_refresh_token.blank?

      token_data = refresh_access_token!(refresh_token: youtube_channel.oauth_refresh_token)

      expires_at =
        if token_data["expires_in"].present?
          Time.current + token_data["expires_in"].to_i.seconds
        else
          youtube_channel.oauth_expires_at
        end

      youtube_channel.update!(
        oauth_access_token: token_data["access_token"],
        oauth_refresh_token: token_data["refresh_token"].presence || youtube_channel.oauth_refresh_token,
        oauth_expires_at: expires_at,
        oauth_scope: token_data["scope"].presence || youtube_channel.oauth_scope,
        oauth_token_type: token_data["token_type"].presence || youtube_channel.oauth_token_type
      )

      youtube_channel.oauth_access_token
    end

    def client_id
      google_credentials.fetch(:client_id)
    end

    def client_secret
      google_credentials.fetch(:client_secret)
    end

    def google_credentials
      Rails.application.credentials.fetch(:google)
    end
  end
end
