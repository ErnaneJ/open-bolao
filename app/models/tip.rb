class Tip < ApplicationRecord
  belongs_to :pool
  belongs_to :user
  belongs_to :match

  validates :pool_id, uniqueness: { scope: [ :user_id, :match_id ] }
  validate :match_not_locked, on: :create
  validate :match_not_locked, on: :update, if: :scores_changed?

  scope :scored,   -> { where.not(points_earned: nil) }
  scope :unscored, -> { where(points_earned: nil) }
  scope :locked,   -> { where.not(locked_at: nil) }
  scope :unlocked, -> { where(locked_at: nil) }

  # Explicitly locked by admin/system (tip-level flag)
  def locked?
    locked_at.present?
  end

  # Lock triggered by match start time + pool's lock_before_minutes buffer
  def time_locked?
    return false unless match.scheduled_at.present?
    deadline = match.scheduled_at - (pool.lock_before_minutes || 0).minutes
    Time.current >= deadline
  end

  # Either hard-locked or time-locked
  def effectively_locked?
    locked? || time_locked? || match.status_live? || match.status_finished? || match.status_cancelled?
  end

  def scored?
    points_earned.present?
  end

  private

  def scores_changed?
    home_score_tip_changed? || away_score_tip_changed?
  end

  def match_not_locked
    errors.add(:base, :tip_locked) if effectively_locked?
  end
end
