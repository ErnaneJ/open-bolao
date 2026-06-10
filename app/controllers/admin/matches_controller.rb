class Admin::MatchesController < Admin::BaseController
  include Pagy::Backend

  before_action :set_pool_if_present
  before_action :set_match, only: [:show, :edit, :update]

  # GET /admin/matches — top-level: browse all matches, create pool from one
  # GET /admin/pools/:pool_id/matches — nested: enter results for pool
  def index
    skip_authorization
    if @pool
      @matches = pool_scoped_matches.order(:scheduled_at)
    else
      base = Match.includes(:home_team, :away_team, :stage, tournament: nil)
      base = base.where("home_teams_matches.name ILIKE ? OR away_teams_matches.name ILIKE ?",
                        "%#{params[:q]}%", "%#{params[:q]}%")
                 .joins("INNER JOIN teams AS home_teams_matches ON matches.home_team_id = home_teams_matches.id")
                 .joins("INNER JOIN teams AS away_teams_matches ON matches.away_team_id = away_teams_matches.id") if params[:q].present?
      base = base.where(tournament_id: params[:tournament_id]) if params[:tournament_id].present?
      base = base.where(status: params[:status]) if params[:status].present?
      @pagy, @matches = pagy(base.order(:scheduled_at), items: 30)
      @tournaments = Tournament.order(:name)
    end
  end

  def show
    skip_authorization
    @pools_for_match = Pool.where(match_id: @match.id)
                           .or(Pool.joins(:pool_matches).where(pool_matches: { match_id: @match.id }))
                           .includes(:admin).order(:name)
  end

  def new
    skip_authorization
    @match = Match.new(
      home_team_id: params[:home_team_id],
      away_team_id: params[:away_team_id],
      scheduled_at: params[:scheduled_at]
    )
  end

  def create
    skip_authorization
    @match = Match.new(match_params)
    if @match.save
      if @pool
        @pool.pool_matches.find_or_create_by!(match: @match)
        redirect_to admin_pool_path(@pool), notice: t("admin.matches.created")
      else
        redirect_to admin_match_path(@match), notice: t("admin.matches.created")
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    skip_authorization
  end

  def update
    skip_authorization
    if @match.update(match_params)
      if @match.status_finished? && @pool
        recalculate_tips_for_match
        Rankings::UpdatePoolRankingService.call(pool: @pool)
      end
      notice = t("admin.matches.updated")
      redirect_to @pool ? admin_pool_matches_path(@pool) : admin_match_path(@match), notice: notice
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_pool_if_present
    return unless params[:pool_id].present?
    @pool = current_user.administered_pools.friendly.find(params[:pool_id])
  rescue ActiveRecord::RecordNotFound
    @pool = Pool.friendly.find(params[:pool_id]) if current_user.role_super_admin?
  end

  def set_match
    @match = params[:pool_id].present? ? pool_scoped_matches.find(params[:id]) : Match.find(params[:id])
  end

  def pool_scoped_matches
    if @pool&.tournament_pool?
      @pool.tournament.matches
    else
      Match.where(id: @pool&.match_id)
    end
  end

  def match_params
    params.require(:match).permit(
      :home_team_id, :away_team_id, :scheduled_at, :status, :venue, :tournament_id, :stage_id,
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
