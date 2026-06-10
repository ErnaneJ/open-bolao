class Admin::MatchesController < Admin::BaseController
  before_action :set_pool
  before_action :set_match, only: [:edit, :update]

  def index
    skip_authorization
    @matches = pool_matches.order(:scheduled_at)
  end

  def new
    @match = Match.new
    authorize @match
  end

  def create
    @match = Match.new(match_params)
    authorize @match
    if @match.save
      redirect_to admin_pool_path(@pool), notice: t("admin.matches.created")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @match
  end

  def update
    authorize @match
    if @match.update(match_params)
      if @match.status_finished?
        recalculate_tips_for_match
        Rankings::UpdatePoolRankingService.call(pool: @pool)
      end
      redirect_to admin_pool_matches_path(@pool), notice: t("admin.matches.updated")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_pool
    @pool = current_user.administered_pools.friendly.find(params[:pool_id])
  rescue ActiveRecord::RecordNotFound
    @pool = Pool.friendly.find(params[:pool_id]) if current_user.role_super_admin?
  end

  def set_match
    @match = pool_matches.find(params[:id])
  end

  def pool_matches
    if @pool.tournament_pool?
      @pool.tournament.matches
    else
      Match.where(id: @pool.match_id)
    end
  end

  def match_params
    params.require(:match).permit(
      :home_team_id, :away_team_id, :scheduled_at, :status, :venue,
      :home_score, :away_score, :home_score_ht, :away_score_ht,
      :home_score_et, :away_score_et, :home_score_penalties, :away_score_penalties,
      :winner_team_id
    )
  end

  def recalculate_tips_for_match
    @pool.tips.where(match: @match).includes(:pool).find_each do |tip|
      Tips::ScoringService.call(tip: tip, match: @match, pool: @pool)
    end
  end
end
