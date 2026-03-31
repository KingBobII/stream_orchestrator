module Youtube
  class SyncAllSchedulesJob < ApplicationJob
    queue_as :default

    def perform
      YoutubeChannel.where(status: "active").where.not(external_id: nil).find_each do |channel|
        Youtube::ScheduleSyncService.new(youtube_channel: channel).call
      rescue StandardError => e
        Rails.logger.error("[Youtube::SyncAllSchedulesJob] failed channel_id=#{channel.id} #{e.class}: #{e.message}")
      end
    end
  end
end
