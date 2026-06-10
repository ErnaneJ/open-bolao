class SpecialBet < ApplicationRecord
  enum :bet_type, {
    champion: 0,
    top_scorer: 1,
    golden_glove: 2,
    best_player: 3,
    finalist_home: 4,
    finalist_away: 5,
    total_goals: 6
  }

  belongs_to :pool
  belongs_to :user
  belongs_to :team, optional: true

  validates :bet_type, presence: true
  validates :pool_id, uniqueness: { scope: [:user_id, :bet_type] }
  validates :integer_value, presence: true, numericality: { only_integer: true }, if: :total_goals?
end
