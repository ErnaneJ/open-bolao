require "rails_helper"

RSpec.describe Pool, type: :model do
  describe "validations" do
    subject { build(:pool) }

    it { should validate_presence_of(:name) }
    it { should validate_length_of(:name).is_at_most(200) }
    it { should validate_presence_of(:pool_scope) }

    context "tournament pool" do
      it "is valid with tournament_id and without match_id" do
        pool = build(:pool, pool_scope: :tournament, tournament: create(:tournament))
        expect(pool).to be_valid
      end

      it "is invalid without tournament_id" do
        pool = build(:pool, pool_scope: :tournament, tournament_id: nil)
        expect(pool).not_to be_valid
        expect(pool.errors[:tournament]).to be_present
      end

      it "is invalid with match_id" do
        pool = build(:pool, pool_scope: :tournament, match: create(:match))
        expect(pool).not_to be_valid
      end
    end

    context "single_match pool" do
      it "is valid with match_id and without tournament_id" do
        match = create(:match)
        pool = build(:pool, pool_scope: :single_match, match: match, tournament: nil)
        expect(pool).to be_valid
      end

      it "is invalid without match_id" do
        pool = build(:pool, pool_scope: :single_match, match_id: nil)
        expect(pool).not_to be_valid
        expect(pool.errors[:match]).to be_present
      end
    end
  end

  describe "#scoring_config_with_defaults" do
    it "merges defaults with custom values" do
      pool = build(:pool, scoring_config: { "exact_score" => 10 })
      config = pool.scoring_config_with_defaults
      expect(config["exact_score"]).to eq(10)
      expect(config["correct_winner"]).to eq(Pool::SCORING_DEFAULTS["correct_winner"])
    end
  end

  describe "invite_code" do
    it "is generated before create" do
      pool = create(:pool)
      expect(pool.invite_code).to be_present
      expect(pool.invite_code.length).to eq(8)
    end
  end
end
