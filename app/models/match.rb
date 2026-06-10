class Match < ApplicationRecord
  enum :status, { scheduled: 0, live: 1, finished: 2, cancelled: 3, postponed: 4 }, prefix: true

  belongs_to :tournament, optional: true
  belongs_to :stage, optional: true
  belongs_to :home_team, class_name: "Team"
  belongs_to :away_team, class_name: "Team"
  belongs_to :winner_team, class_name: "Team", optional: true
  has_many :tips, dependent: :destroy
  has_one :sync_schedule, as: :schedulable, dependent: :destroy

  validates :home_team, presence: true
  validates :away_team, presence: true
  validate :teams_must_differ

  scope :upcoming, -> { where(status: :scheduled).where("scheduled_at > ?", Time.current).order(:scheduled_at) }
  scope :live, -> { where(status: :live) }
  scope :finished, -> { where(status: :finished) }
  scope :today, -> { where(scheduled_at: Time.current.beginning_of_day..Time.current.end_of_day) }
  scope :for_tournament, ->(tournament_id) { where(tournament_id: tournament_id) }
  scope :standalone, -> { where(tournament_id: nil) }

  def result_string
    return nil unless status_finished?
    "#{home_score} x #{away_score}"
  end

  def started?
    scheduled? ? false : true
  end

  def lockable?
    status_scheduled? && scheduled_at.present?
  end

  private

  def teams_must_differ
    errors.add(:away_team, :same_as_home) if home_team_id == away_team_id
  end
end
