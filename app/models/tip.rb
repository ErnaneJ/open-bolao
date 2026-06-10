class Tip < ApplicationRecord
  belongs_to :pool
  belongs_to :user
  belongs_to :match

  validates :pool_id, uniqueness: { scope: [:user_id, :match_id] }
  validate :match_not_locked, on: :create
  validate :match_not_locked, on: :update, if: :scores_changed?

  scope :scored, -> { where.not(points_earned: nil) }
  scope :unscored, -> { where(points_earned: nil) }
  scope :locked, -> { where.not(locked_at: nil) }
  scope :unlocked, -> { where(locked_at: nil) }

  def locked?
    locked_at.present?
  end

  def scored?
    points_earned.present?
  end

  private

  def scores_changed?
    home_score_tip_changed? || away_score_tip_changed?
  end

  def match_not_locked
    return unless locked?
    errors.add(:base, :tip_locked)
  end
end
