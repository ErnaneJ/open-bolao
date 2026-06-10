class SuperAdmin::MatchesController < SuperAdmin::BaseController
  before_action :set_match, only: [:show, :edit, :update]

  def index
    skip_policy_scope
    @pagy, @matches = pagy(Match.includes(:home_team, :away_team, :tournament).order(scheduled_at: :desc))
  end

  def show
    authorize @match
  end

  def edit
    authorize @match
    @teams = Team.by_name
  end

  def update
    authorize @match
    if @match.update(match_params)
      if @match.status_finished?
        Matches::RecalculateTipsJob.perform_later(@match.id)
      end
      redirect_to super_admin_match_path(@match), notice: t("super_admin.matches.updated")
    else
      @teams = Team.by_name
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_match
    @match = Match.find(params[:id])
  end

  def match_params
    params.require(:match).permit(
      :home_team_id, :away_team_id, :scheduled_at, :status, :venue,
      :home_score, :away_score, :home_score_ht, :away_score_ht,
      :home_score_et, :away_score_et, :home_score_penalties, :away_score_penalties,
      :winner_team_id
    )
  end
end
