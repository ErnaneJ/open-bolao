class Admin::SyncLogsController < Admin::BaseController
  before_action :set_pool
  before_action :set_schedule

  def index
    skip_authorization
    @pagy, @logs = pagy(@schedule.sync_logs.recent, items: 30)
  end

  def show
    skip_authorization
    @log = @schedule.sync_logs.find(params[:id])
  end

  private

  def set_pool
    @pool = current_user.role_super_admin? ? Pool.friendly.find(params[:pool_id]) : current_user.administered_pools.friendly.find(params[:pool_id])
  end

  def set_schedule
    schedulable = @pool.tournament_pool? ? @pool.tournament : @pool.match
    @schedule = SyncSchedule.find_by!(schedulable: schedulable)
  end
end
