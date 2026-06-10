class Admin::SyncSchedulesController < Admin::BaseController
  before_action :set_pool
  before_action :set_schedule

  def show
    skip_authorization
    @pagy, @logs = pagy(@schedule.sync_logs.recent, items: 20)
  end

  def edit
    skip_authorization
    @api_providers = ApiProvider.active
  end

  def update
    skip_authorization
    if @schedule.update(schedule_params)
      redirect_to admin_pool_sync_schedule_path(@pool), notice: t("admin.sync.updated")
    else
      @api_providers = ApiProvider.active
      render :edit, status: :unprocessable_entity
    end
  end

  def force_run
    skip_authorization
    if @pool.tournament_pool?
      Sync::FetchResultsJob.perform_later(@pool.tournament_id, "Tournament")
    else
      Sync::FetchResultsJob.perform_later(@pool.match_id, "Match")
    end
    redirect_to admin_pool_sync_schedule_path(@pool), notice: t("admin.sync.forced")
  end

  private

  def set_pool
    @pool = current_user.role_super_admin? ? Pool.friendly.find(params[:pool_id]) : current_user.administered_pools.friendly.find(params[:pool_id])
  end

  def set_schedule
    schedulable = @pool.tournament_pool? ? @pool.tournament : @pool.match
    @schedule = SyncSchedule.find_or_initialize_by(schedulable: schedulable)
  end

  def schedule_params
    params.require(:sync_schedule).permit(
      :enabled, :interval_seconds, :active_from, :active_until,
      :run_only_on_match_days, :api_provider_id, active_weekdays: []
    )
  end
end
