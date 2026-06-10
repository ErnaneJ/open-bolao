require "rails_helper"

RSpec.describe Tips::ScoringService do
  let(:admin) { create(:user, :admin) }
  let(:home_team) { create(:team, name: "Brasil") }
  let(:away_team) { create(:team, name: "Alemanha") }
  let(:tournament) { create(:tournament, created_by: admin) }
  let(:stage) { create(:stage, tournament: tournament, stage_type: :group) }
  let(:match) do
    create(:match, :finished, home_team: home_team, away_team: away_team,
                               tournament: tournament, stage: stage,
                               home_score: 2, away_score: 1)
  end
  let(:pool) { create(:pool, tournament: tournament, admin: admin) }
  let(:user) { create(:user) }
  let(:tip) { create(:tip, pool: pool, user: user, match: match) }

  subject(:service) { described_class.call(tip: tip, match: match, pool: pool) }

  context "when tip is missing" do
    before { tip.update!(home_score_tip: nil, away_score_tip: nil) }

    it "returns no_tip_penalty" do
      expect(service).to eq(pool.scoring_config_with_defaults["no_tip_penalty"])
    end
  end

  context "when exact score is correct (2×1)" do
    before { tip.update!(home_score_tip: 2, away_score_tip: 1) }

    it "awards correct_winner + exact_score" do
      config = pool.scoring_config_with_defaults
      expected = config["correct_winner"] + config["exact_score"]
      expect(service).to eq(expected)
    end
  end

  # match is 2×1 (diff: +1). Tip 3×2 also has diff +1 — correct goal difference but not exact.
  context "when winner and goal difference correct but not exact score (3×2)" do
    before { tip.update!(home_score_tip: 3, away_score_tip: 2) }

    it "awards correct_winner + correct_goal_difference" do
      config = pool.scoring_config_with_defaults
      expected = config["correct_winner"] + config["correct_goal_difference"]
      expect(service).to eq(expected)
    end
  end

  context "when only total goals correct (1×2 tipped, 2×1 real)" do
    before { tip.update!(home_score_tip: 1, away_score_tip: 2) }

    it "awards only correct_total_goals" do
      config = pool.scoring_config_with_defaults
      expect(service).to eq(config["correct_total_goals"])
    end
  end

  # 0×4 = away wins (wrong winner), total 4 ≠ 3 (wrong total), diff -4 ≠ +1 (wrong diff)
  context "when completely wrong (0×4)" do
    before { tip.update!(home_score_tip: 0, away_score_tip: 4) }

    it "returns 0" do
      expect(service).to eq(0)
    end
  end

  context "with knockout multiplier" do
    let(:stage) { create(:stage, :knockout, tournament: tournament) }

    before { tip.update!(home_score_tip: 2, away_score_tip: 1) }

    it "applies knockout multiplier in tournament pool" do
      config = pool.scoring_config_with_defaults
      base = config["correct_winner"] + config["exact_score"]
      expected = (base * config["knockout_multiplier"]).to_i
      expect(service).to eq(expected)
    end
  end

  context "with final multiplier" do
    let(:stage) { create(:stage, :final, tournament: tournament) }

    before { tip.update!(home_score_tip: 2, away_score_tip: 1) }

    it "applies final multiplier" do
      config = pool.scoring_config_with_defaults
      base = config["correct_winner"] + config["exact_score"]
      expected = (base * config["final_multiplier"]).to_i
      expect(service).to eq(expected)
    end
  end

  context "in single_match pool" do
    let(:pool) { create(:pool, :single_match, match: match, admin: admin) }

    before { tip.update!(home_score_tip: 2, away_score_tip: 1) }

    it "does not apply stage multipliers" do
      config = pool.scoring_config_with_defaults
      expected = config["correct_winner"] + config["exact_score"]
      expect(service).to eq(expected)
    end
  end
end
