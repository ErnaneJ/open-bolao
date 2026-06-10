class Tournament < ApplicationRecord
  extend FriendlyId
  friendly_id :name, use: :slugged

  enum :sport, { football: 0 }
  enum :status, { draft: 0, active: 1, finished: 2 }, prefix: true
  enum :external_provider, { none: 0, worldcup2026_api: 1, api_football: 2, custom: 3 }

  belongs_to :created_by, class_name: "User"
  has_many :tournament_teams, dependent: :destroy
  has_many :teams, through: :tournament_teams
  has_many :stages, -> { order(:order_position) }, dependent: :destroy
  has_many :matches, dependent: :destroy
  has_many :pools, dependent: :nullify
  has_one :sync_schedule, as: :schedulable, dependent: :destroy

  has_one_attached :logo

  validates :name, presence: true, length: { maximum: 200 }
  validates :sport, presence: true
  validates :status, presence: true

  scope :active, -> { where(status: :active) }
  scope :by_season, -> { order(season: :desc) }
end
