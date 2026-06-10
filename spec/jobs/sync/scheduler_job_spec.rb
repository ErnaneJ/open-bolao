require "rails_helper"

RSpec.describe Sync::SchedulerJob do
  subject(:job) { described_class.new }

  let(:schedule) { create(:sync_schedule, enabled: true, interval_seconds: 120, run_only_on_match_days: false) }

  describe "#perform" do
    context "when schedule is due and within window" do
      before { schedule.update!(last_run_at: 3.minutes.ago) }

      it "enqueues FetchResultsJob" do
        expect { job.perform }
          .to have_enqueued_job(Sync::FetchResultsJob)
          .with(schedule.schedulable_id, schedule.schedulable_type)
      end

      it "updates last_run_at" do
        freeze_time do
          job.perform
          expect(schedule.reload.last_run_at).to be_within(1.second).of(Time.current)
        end
      end
    end

    context "when schedule is paused" do
      before { schedule.update!(paused_until: 30.minutes.from_now) }

      it "does not enqueue FetchResultsJob" do
        expect { job.perform }.not_to have_enqueued_job(Sync::FetchResultsJob)
      end
    end

    context "when not due yet" do
      before { schedule.update!(last_run_at: 30.seconds.ago) }

      it "does not enqueue FetchResultsJob" do
        expect { job.perform }.not_to have_enqueued_job(Sync::FetchResultsJob)
      end
    end

    context "when outside active time window" do
      before do
        schedule.update!(
          active_from: Time.current.change(hour: 0, min: 0),
          active_until: Time.current.change(hour: 0, min: 1)
        )
      end

      it "does not enqueue FetchResultsJob" do
        expect { job.perform }.not_to have_enqueued_job(Sync::FetchResultsJob)
      end
    end

    context "when run_only_on_match_days and no matches today" do
      let(:schedule) do
        create(:sync_schedule, enabled: true, interval_seconds: 60,
               run_only_on_match_days: true)
      end

      before { schedule.update!(last_run_at: 5.minutes.ago) }

      it "does not enqueue FetchResultsJob" do
        expect { job.perform }.not_to have_enqueued_job(Sync::FetchResultsJob)
      end
    end
  end
end
