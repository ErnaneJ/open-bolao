require "rails_helper"

RSpec.describe Sync::SchedulerJob do
  subject(:job) { described_class.new }

  describe "#perform" do
    context "when schedule is due and within window" do
      let!(:schedule) { create(:sync_schedule, enabled: true, interval_seconds: 120, run_only_on_match_days: false, last_run_at: 3.minutes.ago) }

      it "enqueues FetchResultsJob" do
        expect { job.perform }
          .to have_enqueued_job(Sync::FetchResultsJob)
          .with(schedule.schedulable_id, schedule.schedulable_type)
      end

      it "updates last_run_at" do
        before_run = Time.current
        job.perform
        expect(schedule.reload.last_run_at).to be >= before_run
      end
    end

    context "when schedule is paused" do
      let!(:schedule) { create(:sync_schedule, enabled: true, run_only_on_match_days: false, paused_until: 30.minutes.from_now) }

      it "does not enqueue FetchResultsJob" do
        expect { job.perform }.not_to have_enqueued_job(Sync::FetchResultsJob)
      end
    end

    context "when not due yet (ran 30s ago, interval 120s)" do
      let!(:schedule) { create(:sync_schedule, enabled: true, interval_seconds: 120, run_only_on_match_days: false, last_run_at: 30.seconds.ago) }

      it "does not enqueue FetchResultsJob" do
        expect { job.perform }.not_to have_enqueued_job(Sync::FetchResultsJob)
      end
    end

    context "when outside active time window (00:00–00:01)" do
      let!(:schedule) do
        create(:sync_schedule, enabled: true, interval_seconds: 60, run_only_on_match_days: false,
               last_run_at: 5.minutes.ago,
               active_from: Time.current.change(hour: 0, min: 0),
               active_until: Time.current.change(hour: 0, min: 1))
      end

      it "does not enqueue FetchResultsJob outside midnight window" do
        skip "only meaningful outside 00:00–00:01" if Time.current.strftime("%H:%M") <= "00:01"
        expect { job.perform }.not_to have_enqueued_job(Sync::FetchResultsJob)
      end
    end

    context "when run_only_on_match_days and no matches today" do
      let!(:schedule) do
        create(:sync_schedule, enabled: true, interval_seconds: 60,
               run_only_on_match_days: true, last_run_at: 5.minutes.ago)
      end

      it "does not enqueue FetchResultsJob" do
        expect { job.perform }.not_to have_enqueued_job(Sync::FetchResultsJob)
      end
    end
  end
end
