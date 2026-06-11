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
      flash[:notice] = t("pools.created")
      respond_to do |format|
        format.turbo_stream do
          # Frame requests can't redirect to a page without the frame — use a
          # custom stream action to trigger a full-page Turbo visit instead.
          render turbo_stream: "<turbo-stream action='redirect' target='#{admin_pool_path(@pool)}'></turbo-stream>"
        end
        format.html { redirect_to admin_pool_path(@pool) }
      end
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
