require "rails_helper"

RSpec.describe Sync::FetchResultsJob do
  subject(:job) { described_class.new }

  let(:api_provider) { create(:api_provider) }
  let(:tournament) { create(:tournament) }
  let(:schedule) { create(:sync_schedule, schedulable: tournament, api_provider: api_provider) }
  let(:home_team) { create(:team) }
  let(:away_team) { create(:team) }
  let(:match) do
    create(:match, tournament: tournament, home_team: home_team, away_team: away_team,
                   external_id: "ext-123", status: :live, home_score: 0, away_score: 0)
  end

  let(:match_data) do
    ApiProviders::Worldcup2026Adapter::MatchData.new(
      external_id: "ext-123",
      home_team_name: home_team.name,
      away_team_name: away_team.name,
      scheduled_at: match.scheduled_at,
      status: :live,
      home_score: 1,
      away_score: 0,
      group_name: "Group A"
    )
  end

  before do
    match # ensure match exists
    allow_any_instance_of(ApiProviders::Worldcup2026Adapter)
      .to receive(:fetch_results).and_return([match_data])
  end

  describe "#perform" do
    it "creates a SyncLog" do
      expect { job.perform(tournament.id, "Tournament") }
        .to change(SyncLog, :count).by(1)
    end

    it "updates match score when goal detected" do
      job.perform(tournament.id, "Tournament")
      expect(match.reload.home_score).to eq(1)
    end

    it "creates a success SyncLog" do
      job.perform(tournament.id, "Tournament")
      log = SyncLog.last
      expect(log.status).to eq("success")
      expect(log.goals_detected).to eq(1)
      expect(log.matches_updated).to eq(1)
    end

    context "when match finishes" do
      let(:match_data) do
        ApiProviders::Worldcup2026Adapter::MatchData.new(
          external_id: "ext-123",
          home_team_name: home_team.name,
          away_team_name: away_team.name,
          scheduled_at: match.scheduled_at,
          status: :finished,
          home_score: 2,
          away_score: 1,
          group_name: nil
        )
      end

      it "enqueues RecalculateTipsJob" do
        expect { job.perform(tournament.id, "Tournament") }
          .to have_enqueued_job(Matches::RecalculateTipsJob)
      end
    end

    context "when adapter raises an error" do
      before do
        allow_any_instance_of(ApiProviders::Worldcup2026Adapter)
          .to receive(:fetch_results).and_raise(RuntimeError, "API down")
      end

      it "increments consecutive_failures" do
        expect { job.perform(tournament.id, "Tournament") }.to raise_error(RuntimeError)
        expect(schedule.reload.consecutive_failures).to eq(1)
      end

      it "creates a failed SyncLog" do
        expect { job.perform(tournament.id, "Tournament") }.to raise_error(RuntimeError)
        expect(SyncLog.last.status).to eq("failed")
      end

      context "after 5 failures" do
        before { schedule.update!(consecutive_failures: 4) }

        it "auto-pauses the schedule" do
          expect { job.perform(tournament.id, "Tournament") }.to raise_error(RuntimeError)
          expect(schedule.reload.paused_until).to be > Time.current
        end
      end
    end
  end
end
