# module Youtube
#   class SyncStreamJob < ApplicationJob
#     queue_as :default

#     def perform(stream_id)
#       stream = Stream.find_by(id: stream_id)
#       return unless stream
#       return if stream.synced?
#       return unless stream.ready_for_sync? || stream.failed_sync?

#       Youtube::BroadcastCreator.new(stream).call
#     end
#   end
# end
module Youtube
  class SyncStreamJob < ApplicationJob
    queue_as :default

    def perform(stream_id)
      Rails.logger.info("[Youtube::SyncStreamJob] starting stream_id=#{stream_id}")

      stream = Stream.find_by(id: stream_id)
      unless stream
        Rails.logger.warn("[Youtube::SyncStreamJob] stream not found stream_id=#{stream_id}")
        return
      end

      Rails.logger.info("[Youtube::SyncStreamJob] found stream #{stream.id} status=#{stream.status} syncing=#{stream.syncing?} syncable=#{stream.syncable_to_youtube?}")

      unless stream.syncable_to_youtube?
        Rails.logger.info("[Youtube::SyncStreamJob] stream not syncable stream_id=#{stream.id}")
        return
      end

      if stream.syncing?
        Rails.logger.info("[Youtube::SyncStreamJob] stream already syncing stream_id=#{stream.id}")
        return
      end

      if stream.youtube_broadcast_id.present?
        Rails.logger.info("[Youtube::SyncStreamJob] updating broadcast stream_id=#{stream.id} broadcast_id=#{stream.youtube_broadcast_id}")
        Youtube::BroadcastUpdater.new(stream).call
      else
        Rails.logger.info("[Youtube::SyncStreamJob] creating broadcast stream_id=#{stream.id}")
        Youtube::BroadcastCreator.new(stream).call
      end

      Rails.logger.info("[Youtube::SyncStreamJob] finished stream_id=#{stream.id}")
    rescue StandardError => e
      Rails.logger.error("[Youtube::SyncStreamJob] failed stream_id=#{stream_id} #{e.class}: #{e.message}")
      raise
    end
  end
end
