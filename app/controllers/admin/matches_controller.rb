class Admin::MatchesController < Admin::BaseController
  include Pagy::Backend


  before_action :set_pool_if_present
  before_action :set_match, only: [ :show, :edit, :update ]

  # GET /admin/matches — top-level: browse all matches, create pool from one
  # GET /admin/pools/:pool_id/matches — nested: enter results for pool
  def index
    skip_authorization
    if @pool
      @matches = pool_scoped_matches.order(:scheduled_at)
    else
      base = Match.includes(:home_team, :away_team, :stage, tournament: nil)
      if params[:q].present?
        base = base
          .joins("INNER JOIN teams AS ht ON matches.home_team_id = ht.id")
          .joins("INNER JOIN teams AS at ON matches.away_team_id = at.id")
          .where("ht.name ILIKE :q OR at.name ILIKE :q", q: "%#{params[:q]}%")
      end
      base = base.where(tournament_id: params[:tournament_id]) if params[:tournament_id].present?
      base = base.where(status: params[:status]) if params[:status].present?
      @pagy, @matches = pagy(base.order(:scheduled_at), items: 30)
      @tournaments = Tournament.order(:name)

      respond_to do |format|
        format.html
        format.json do
          render json: @matches.map { |m|
            {
              id: m.id,
              label: "#{m.home_team.name} × #{m.away_team.name}",
              home_flag: m.home_team.flag_url,
              away_flag: m.away_team.flag_url,
              date: m.scheduled_at ? m.scheduled_at.in_time_zone("America/Fortaleza").strftime("%d/%m %H:%M") : nil
            }
          }
        end
      end
    end
  end

  def sync_from_api
    skip_authorization
    unless @pool&.tournament_pool? && @pool.tournament.present?
      return redirect_to(admin_pool_matches_path(@pool), alert: "Bolão sem torneio associado.")
    end

    Sync::FetchResultsJob.perform_later(@pool.tournament_id, "Tournament")
    redirect_to admin_pool_matches_path(@pool), notice: "Sincronização com a API enfileirada. Os placares serão atualizados em instantes."
  end

  def show
    skip_authorization
    @pools_for_match = Pool.where(match_id: @match.id)
                           .or(Pool.where(id: PoolMatch.where(match_id: @match.id).select(:pool_id)))
                           .includes(:admin).order(:name)
  end

  def new
    skip_authorization
    @match = Match.new(
      home_team_id: params[:home_team_id],
      away_team_id: params[:away_team_id],
      scheduled_at: params[:scheduled_at]
    )
    @teams = Team.order(:name)
    @tournaments = Tournament.order(:name)
    @stages = Stage.order(:name)
    render layout: "admin_fullscreen"
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
    @teams = Team.order(:name)
    @tournaments = Tournament.order(:name)
    @stages = @match.tournament ? @match.tournament.stages.order(:order_position) : Stage.order(:name)
    render layout: "admin_fullscreen"
  end

  def update
    skip_authorization
    was_finished = @match.status_finished?
    if @match.update(match_params)
      if @match.status_finished? && !was_finished
        recalculate_tips_for_match if @pool
        pools_for_match(@match).each do |pool|
          Rankings::UpdatePoolRankingService.call(pool: pool)
          Matches::RecalculateTipsJob.perform_later(@match.id)
        end
      end
      notice = t("admin.matches.updated")
      back = @pool ? admin_pool_matches_path(@pool) : admin_matches_path
      redirect_to back, notice: notice
    else
      @teams = Team.order(:name)
      @tournaments = Tournament.order(:name)
      @stages = @match.tournament ? @match.tournament.stages.order(:order_position) : Stage.order(:name)
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
      :home_team_id, :away_team_id, :scheduled_at, :status, :venue,
      :tournament_id, :stage_id, :winner_team_id,
      :home_score, :away_score,
      :home_score_ht, :away_score_ht,
      :home_score_et, :away_score_et,
      :home_score_penalties, :away_score_penalties,
      :stream_url, :thumb_url,
      :external_id, :external_provider_name, :external_tsdb_id
    )
  end

  def pools_for_match(match)
    Pool.joins(:pool_matches).where(pool_matches: { match_id: match.id })
        .or(Pool.where(tournament_id: match.tournament_id))
  end

  def recalculate_tips_for_match
    @pool.tips.where(match: @match).includes(:pool).find_each do |tip|
      Tips::ScoringService.call(tip: tip, match: @match, pool: @pool)
    end
  end
end
