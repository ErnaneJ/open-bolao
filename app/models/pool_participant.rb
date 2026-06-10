class PoolParticipant < ApplicationRecord
  enum :status, { pending: 0, active: 1, banned: 2 }, prefix: true
  enum :rank_trend, { down: 0, same: 1, up: 2 }, prefix: true

  belongs_to :pool
  belongs_to :user

  validates :pool_id, uniqueness: { scope: :user_id }

  scope :active, -> { where(status: :active) }
  scope :ranked, -> { where.not(rank: nil).order(:rank) }

  before_create :set_joined_at

  private

  def set_joined_at
    self.joined_at ||= Time.current
  end
end
