class Notification < ApplicationRecord
  enum :kind, {
    match_starting: 0,
    goal: 1,
    match_finished: 2,
    rank_changed: 3,
    pool_invite: 4,
    pool_finished: 5
  }, prefix: true

  belongs_to :user
  belongs_to :notifiable, polymorphic: true, optional: true

  validates :kind, presence: true
  validates :title, presence: true

  scope :unread, -> { where(read_at: nil) }
  scope :recent, -> { order(created_at: :desc) }

  def read?
    read_at.present?
  end

  def mark_as_read!
    update!(read_at: Time.current) unless read?
  end
end
