class SuperAdmin::PoolsController < SuperAdmin::BaseController
  before_action :set_pool, only: [ :show, :edit, :update, :destroy ]

  def index
    skip_policy_scope
    @pagy, @pools = pagy(Pool.includes(:admin, :tournament).order(created_at: :desc))
  end

  def show
    authorize @pool
  end

  def edit
    authorize @pool
    @tournaments = Tournament.all
    @matches = Match.includes(:home_team, :away_team).order(:scheduled_at).limit(100)
  end

  def update
    authorize @pool
    if @pool.update(pool_params)
      redirect_to super_admin_pool_path(@pool), notice: t("super_admin.pools.updated")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @pool
    @pool.destroy!
    redirect_to super_admin_pools_path, notice: t("super_admin.pools.destroyed")
  end

  private

  def set_pool
    @pool = Pool.friendly.find(params[:id])
  end

  def pool_params
    params.require(:pool).permit(
      :name, :description, :status, :visibility, :max_participants,
      :allow_late_entries, :lock_before_minutes,
      scoring_config: Pool::SCORING_DEFAULTS.keys
    )
  end
end
