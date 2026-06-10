module Sync
  class PurgeLogsJob < ApplicationJob
    queue_as :default

    def perform
      SyncSchedule.find_each do |schedule|
        excess = schedule.sync_logs
                         .order(created_at: :desc)
                         .offset(SyncLog::MAX_LOGS_PER_SCHEDULE)
        SyncLog.where(id: excess.select(:id)).delete_all
      end
    end
  end
end
