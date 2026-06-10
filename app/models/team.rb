class Team < ApplicationRecord
  belongs_to :created_by, class_name: "User", optional: true
  has_many :tournament_teams, dependent: :destroy
  has_many :tournaments, through: :tournament_teams
  has_many :home_matches, class_name: "Match", foreign_key: :home_team_id, dependent: :nullify
  has_many :away_matches, class_name: "Match", foreign_key: :away_team_id, dependent: :nullify

  has_one_attached :logo

  validates :name, presence: true, length: { maximum: 100 }
  validates :short_name, length: { maximum: 10 }, allow_blank: true
  validates :country_code, length: { maximum: 3 }, allow_blank: true

  scope :by_name, -> { order(:name) }
  scope :search_by_name, ->(q) { where("name ILIKE ?", "%#{q}%") }
end
