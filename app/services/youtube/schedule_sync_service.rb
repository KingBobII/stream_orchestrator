module Youtube
  class ScheduleSyncService
    def initialize(youtube_channel:)
      @youtube_channel = youtube_channel
      @client = build_client
    end

    def call
      broadcasts = fetch_all_broadcasts
      streams = fetch_all_streams.index_by(&:id)

      broadcasts.each do |broadcast|
        bound_stream_id = broadcast.content_details&.bound_stream_id
        next if bound_stream_id.blank?

        yt_stream = streams[bound_stream_id]
        next if yt_stream.nil?

        record = Stream.find_or_initialize_by(
          youtube_channel_id: youtube_channel.id,
          youtube_broadcast_id: broadcast.id
        )

        ingestion = yt_stream.cdn&.ingestion_info

        record.assign_attributes(
          title: broadcast.snippet&.title.presence || record.title,
          description: broadcast.snippet&.description.presence || record.description,
          scheduled_at: parse_time(broadcast.snippet&.scheduled_start_time) || record.scheduled_at,

          youtube_stream_id: yt_stream.id,
          youtube_stream_name: ingestion&.stream_name,
          youtube_ingestion_address: ingestion&.ingestion_address,
          youtube_backup_ingestion_address: ingestion&.backup_ingestion_address,
          youtube_rtmps_ingestion_address: ingestion&.rtmps_ingestion_address,
          youtube_rtmps_backup_ingestion_address: ingestion&.rtmps_backup_ingestion_address,

          sync_status: "synced",
          synced_at: Time.current,
          youtube_synced_at: Time.current,

          venue_type: record.venue_type.presence || "virtual",
          venue_name: record.venue_name.presence || "Virtual"
        )

        record.status = mapped_status(broadcast)
        record.save!
      end
    end

    private

    attr_reader :youtube_channel, :client

    def build_client
      service = Google::Apis::YoutubeV3::YouTubeService.new

      service.authorization = Google::Auth::UserRefreshCredentials.new(
        client_id: ENV.fetch("GOOGLE_CLIENT_ID"),
        client_secret: ENV.fetch("GOOGLE_CLIENT_SECRET"),
        refresh_token: youtube_channel.google_refresh_token, # change this if your column name differs
        scope: ["https://www.googleapis.com/auth/youtube.force-ssl"]
      )

      service
    end

    def fetch_all_broadcasts
      items = []
      page_token = nil

      loop do
        response = client.list_live_broadcasts(
          "id,snippet,contentDetails,status",
          mine: true,
          broadcast_status: "all",
          max_results: 50,
          page_token: page_token
        )

        items.concat(response.items || [])
        page_token = response.next_page_token
        break if page_token.blank?
      end

      items
    end

    def fetch_all_streams
      items = []
      page_token = nil

      loop do
        response = client.list_live_streams(
          "id,snippet,cdn,status",
          mine: true,
          max_results: 50,
          page_token: page_token
        )

        items.concat(response.items || [])
        page_token = response.next_page_token
        break if page_token.blank?
      end

      items
    end

    def parse_time(value)
      return nil if value.blank?

      Time.zone.parse(value.to_s)
    end

    def mapped_status(broadcast)
      case broadcast.status&.life_cycle_status
      when "live"
        "live"
      when "complete"
        "ended"
      when "revoked"
        "cancelled"
      else
        "scheduled"
      end
    end
  end
end
