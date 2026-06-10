class SuperAdmin::TournamentTeamsController < SuperAdmin::BaseController
  before_action :set_tournament

  def index
    skip_authorization
    @tournament_teams = @tournament.tournament_teams.includes(:team).order("teams.name")
  end

  def new
    skip_authorization
    @tournament_team = @tournament.tournament_teams.build
    @teams = Team.by_name
  end

  def create
    skip_authorization
    @tournament_team = @tournament.tournament_teams.build(tournament_team_params)
    if @tournament_team.save
      redirect_to super_admin_tournament_teams_path(@tournament), notice: t("super_admin.tournament_teams.created")
    else
      @teams = Team.by_name
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    skip_authorization
    @tournament.tournament_teams.find(params[:id]).destroy!
    redirect_to super_admin_tournament_teams_path(@tournament), notice: t("super_admin.tournament_teams.destroyed")
  end

  private

  def set_tournament
    @tournament = Tournament.friendly.find(params[:tournament_id])
  end

  def tournament_team_params
    params.require(:tournament_team).permit(:team_id, :group_name, :external_id)
  end
end
