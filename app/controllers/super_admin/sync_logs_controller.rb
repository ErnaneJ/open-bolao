class SuperAdmin::SyncLogsController < SuperAdmin::BaseController
  before_action :set_tournament
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

  def set_tournament
    @tournament = Tournament.friendly.find(params[:tournament_id])
  end

  def set_schedule
    @schedule = SyncSchedule.find_by!(schedulable: @tournament)
  end
end
