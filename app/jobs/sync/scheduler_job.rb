module Sync
  class SchedulerJob < ApplicationJob
    queue_as :scheduler

    def perform
      SyncSchedule.ready_to_run.find_each do |schedule|
        next unless schedule.should_run?
        Sync::FetchResultsJob.perform_later(schedule.schedulable_id, schedule.schedulable_type)
        schedule.update_column(:last_run_at, Time.current)
      end
    end
  end
end
