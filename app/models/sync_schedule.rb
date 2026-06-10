class SyncSchedule < ApplicationRecord
  MAX_CONSECUTIVE_FAILURES = 5
  AUTO_PAUSE_MINUTES = 30

  belongs_to :schedulable, polymorphic: true
  belongs_to :api_provider, optional: true
  has_many :sync_logs, dependent: :destroy

  validates :interval_seconds, presence: true,
            numericality: { only_integer: true, greater_than: 0 }
  validates :schedulable, presence: true

  scope :enabled, -> { where(enabled: true) }
  scope :not_paused, -> { where("paused_until IS NULL OR paused_until < ?", Time.current) }
  scope :ready_to_run, -> { enabled.not_paused }

  def paused?
    paused_until.present? && paused_until > Time.current
  end

  def due?
    last_run_at.nil? || (Time.current - last_run_at) >= interval_seconds
  end

  def within_active_window?
    return true if active_from.nil? || active_until.nil?
    now = Time.current.strftime("%H:%M")
    now >= active_from.strftime("%H:%M") && now <= active_until.strftime("%H:%M")
  end

  def active_today?
    return true if active_weekdays.blank?
    active_weekdays.include?(Time.current.wday)
  end

  def has_matches_today?
    case schedulable
    when Tournament
      schedulable.matches.today.exists?
    when Match
      schedulable.scheduled_at&.today?
    else
      true
    end
  end

  def should_run?
    return false if paused?
    return false unless within_active_window?
    return false unless active_today?
    return false if run_only_on_match_days && !has_matches_today?
    due?
  end

  def record_failure!(message)
    increment!(:consecutive_failures)
    update!(last_error_message: message)
    if consecutive_failures >= MAX_CONSECUTIVE_FAILURES
      update!(paused_until: AUTO_PAUSE_MINUTES.minutes.from_now)
    end
  end

  def record_success!
    update!(consecutive_failures: 0, last_success_at: Time.current, last_error_message: nil)
  end
end
