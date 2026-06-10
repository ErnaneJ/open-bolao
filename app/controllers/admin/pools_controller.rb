class Admin::PoolsController < Admin::BaseController
  include Pagy::Backend
  before_action :set_pool, only: [:show, :edit, :update, :destroy, :recalculate, :transition]

  def index
    skip_policy_scope
    @pagy, @pools = pagy(current_user.administered_pools.includes(:tournament, :match).order(created_at: :desc))
  end

  def show
    authorize @pool
  end

  def new
    @pool = Pool.new
    authorize @pool
  end

  def create
    @pool = current_user.administered_pools.build(pool_params)
    authorize @pool
    if @pool.save
      redirect_to admin_pool_path(@pool), notice: t("admin.pools.created")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @pool
  end

  def update
    authorize @pool
    if @pool.update(pool_params)
      redirect_to admin_pool_path(@pool), notice: t("admin.pools.updated")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @pool
    @pool.destroy!
    redirect_to admin_pools_path, notice: t("admin.pools.destroyed")
  end

  def recalculate
    authorize @pool
    recalculate_all_tips
    Rankings::UpdatePoolRankingService.call(pool: @pool)
    redirect_to admin_pool_path(@pool), notice: t("admin.pools.recalculated")
  end

  def transition
    authorize @pool
    new_status = params[:status]
    if Pool.statuses.key?(new_status)
      @pool.update!(status: new_status)
      redirect_to admin_pool_path(@pool), notice: t("admin.pools.status_updated")
    else
      redirect_to admin_pool_path(@pool), alert: t("admin.pools.invalid_status")
    end
  end

  private

  def set_pool
    @pool = current_user.administered_pools.friendly.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    @pool = Pool.friendly.find(params[:id]) if current_user.role_super_admin?
  end

  def pool_params
    params.require(:pool).permit(
      :name, :description, :pool_scope, :tournament_id, :match_id,
      :status, :visibility, :entry_fee, :prize_description, :max_participants,
      :allow_late_entries, :lock_before_minutes, :starts_at, :ends_at,
      scoring_config: Pool::SCORING_DEFAULTS.keys
    )
  end

  def recalculate_all_tips
    @pool.tips.includes(:match, :pool).find_each do |tip|
      Tips::ScoringService.call(tip: tip, match: tip.match, pool: @pool) if tip.match.status_finished?
    end
  end
end
