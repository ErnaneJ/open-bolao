class SyncLog < ApplicationRecord
  MAX_LOGS_PER_SCHEDULE = 500

  enum :status, { success: 0, partial: 1, failed: 2, skipped: 3 }, prefix: true

  belongs_to :sync_schedule

  validates :status, presence: true

  scope :recent, -> { order(started_at: :desc) }
  scope :failures, -> { where(status: [:failed, :partial]) }

  after_create :purge_old_logs

  private

  def purge_old_logs
    excess = sync_schedule.sync_logs.order(created_at: :desc).offset(MAX_LOGS_PER_SCHEDULE)
    SyncLog.where(id: excess.select(:id)).delete_all
  end
end
