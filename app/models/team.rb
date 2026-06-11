class Team < ApplicationRecord
  belongs_to :created_by, class_name: "User", optional: true
  has_many :tournament_teams, dependent: :destroy
  has_many :tournaments, through: :tournament_teams
  has_many :home_matches, class_name: "Match", foreign_key: :home_team_id, dependent: :restrict_with_error
  has_many :away_matches, class_name: "Match", foreign_key: :away_team_id, dependent: :restrict_with_error

  has_one_attached :logo

  validates :name, presence: true, length: { maximum: 100 }
  validates :short_name, length: { maximum: 10 }, allow_blank: true
  validates :country_code, length: { maximum: 3 }, allow_blank: true

  scope :by_name, -> { order(:name) }

  scope :search_by_name, ->(q) { where("name ILIKE ?", "%#{q}%") }

  # Best available image URL for display (prefers logo over flag)
  def display_image_url
    logo_url.presence || flag_url.presence
  end

  def initials
    (short_name.presence || name.split.map(&:first).first(3).join).upcase.first(3)
  end
end
