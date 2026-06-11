class SuperAdmin::TournamentMatchesController < SuperAdmin::BaseController
  before_action :set_tournament
  before_action :set_match, only: [ :show, :edit, :update, :destroy ]

  def index
    skip_authorization
    @pagy, @matches = pagy(@tournament.matches.includes(:home_team, :away_team, :stage).order(:scheduled_at))
  end

  def new
    @match = @tournament.matches.build
    skip_authorization
    @teams = @tournament.teams.by_name
    @stages = @tournament.stages.ordered
  end

  def create
    @match = @tournament.matches.build(match_params)
    skip_authorization
    if @match.save
      redirect_to super_admin_tournament_matches_path(@tournament), notice: t("super_admin.matches.created")
    else
      @teams = @tournament.teams.by_name
      @stages = @tournament.stages.ordered
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    skip_authorization
    @teams = @tournament.teams.by_name
    @stages = @tournament.stages.ordered
  end

  def update
    skip_authorization
    if @match.update(match_params)
      Matches::RecalculateTipsJob.perform_later(@match.id) if @match.status_finished?
      redirect_to super_admin_tournament_matches_path(@tournament), notice: t("super_admin.matches.updated")
    else
      @teams = @tournament.teams.by_name
      @stages = @tournament.stages.ordered
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    skip_authorization
    @match.destroy!
    redirect_to super_admin_tournament_matches_path(@tournament), notice: t("super_admin.matches.destroyed")
  end

  private

  def set_tournament
    @tournament = Tournament.friendly.find(params[:tournament_id])
  end

  def set_match
    @match = @tournament.matches.find(params[:id])
  end

  def match_params
    params.require(:match).permit(
      :home_team_id, :away_team_id, :stage_id, :scheduled_at, :status, :venue,
      :home_score, :away_score, :home_score_ht, :away_score_ht,
      :home_score_et, :away_score_et, :home_score_penalties, :away_score_penalties,
      :winner_team_id, :external_id
    )
  end
end
