class TournamentTeam < ApplicationRecord
  belongs_to :tournament
  belongs_to :team

  validates :tournament_id, uniqueness: { scope: :team_id }
end
