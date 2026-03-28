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

      Rails.logger.info(
        "[Youtube::SyncStreamJob] found stream #{stream.id} status=#{stream.status} syncing=#{stream.syncing?} syncable=#{stream.syncable_to_youtube?}"
      )

      unless stream.syncable_to_youtube?
        Rails.logger.info("[Youtube::SyncStreamJob] stream not syncable stream_id=#{stream.id}")
        return
      end

      if stream.syncing?
        Rails.logger.info("[Youtube::SyncStreamJob] stream already syncing stream_id=#{stream.id}")
        return
      end

      if stream.youtube_broadcast_id.present?
        Rails.logger.info("[Youtube::SyncStreamJob] updating broadcast stream_id=#{stream.id}")
        result = Youtube::BroadcastUpdater.new(stream).call
      else
        Rails.logger.info("[Youtube::SyncStreamJob] creating broadcast stream_id=#{stream.id}")
        result = Youtube::BroadcastCreator.new(stream).call
      end

      if result.respond_to?(:status) && result.status == "failed"
        raise StandardError, result.error.presence || "YouTube sync failed"
      end

      Rails.logger.info("[Youtube::SyncStreamJob] finished stream_id=#{stream.id}")
    rescue StandardError => e
      Rails.logger.error("[Youtube::SyncStreamJob] failed stream_id=#{stream_id} #{e.class}: #{e.message}")
      raise
    end
  end
end
