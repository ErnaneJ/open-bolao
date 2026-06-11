class MyPoolsController < ApplicationController
  before_action :set_pool, only: [ :edit, :update, :destroy ]

  def new
    @pool = Pool.new(lock_before_minutes: 5, timezone: "America/Fortaleza",
                     visibility: :invite_only)
    authorize @pool
    @tournaments = Tournament.order(:name)
  end

  def create
    @pool = current_user.administered_pools.build(pool_params)
    authorize @pool
    if @pool.save
      # When submitted from the drawer (turbo frame), break out to top-level navigation.
      # This closes the drawer naturally and redirects the whole page.
      response.headers["Turbo-Frame"] = "_top" if turbo_frame_request?
      redirect_to admin_pool_path(@pool), notice: t("pools.created")
    else
      @tournaments = Tournament.order(:name)
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @tournaments = Tournament.order(:name)
    authorize @pool
  end

  def update
    authorize @pool
    if @pool.update(pool_params)
      redirect_to admin_pool_path(@pool), notice: t("pools.updated")
    else
      @tournaments = Tournament.order(:name)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @pool
    @pool.destroy!
    redirect_to dashboard_path, notice: t("pools.destroyed")
  end

  private

  def set_pool
    @pool = current_user.administered_pools.friendly.find(params[:id])
  end

  def pool_params
    params.require(:pool).permit(
      :name, :description, :pool_scope, :tournament_id, :match_id,
      :visibility, :max_participants, :lock_before_minutes,
      :entry_fee, :prize_description, :starts_at, :ends_at, :timezone,
      scoring_config: Pool::SCORING_DEFAULTS.keys
    )
  end
end
