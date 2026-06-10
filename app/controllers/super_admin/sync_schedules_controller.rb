class SuperAdmin::SyncSchedulesController < SuperAdmin::BaseController
  before_action :set_tournament
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
      redirect_to super_admin_tournament_sync_schedule_path(@tournament), notice: t("admin.sync.updated")
    else
      @api_providers = ApiProvider.active
      render :edit, status: :unprocessable_entity
    end
  end

  def force_run
    skip_authorization
    Sync::FetchResultsJob.perform_later(@tournament.id, "Tournament")
    redirect_to super_admin_tournament_sync_schedule_path(@tournament), notice: t("admin.sync.forced")
  end

  private

  def set_tournament
    @tournament = Tournament.friendly.find(params[:tournament_id])
  end

  def set_schedule
    @schedule = SyncSchedule.find_or_initialize_by(schedulable: @tournament)
  end

  def schedule_params
    params.require(:sync_schedule).permit(
      :enabled, :interval_seconds, :active_from, :active_until,
      :run_only_on_match_days, :api_provider_id, active_weekdays: []
    )
  end
end
