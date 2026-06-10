class ApiProvider < ApplicationRecord
  enum :provider_type, { worldcup2026: 0, api_football: 1, custom: 2, thesportsdb: 3 }

  has_many :sync_schedules, dependent: :nullify

  validates :name, presence: true
  validates :provider_type, presence: true

  scope :active, -> { where(active: true) }
end
