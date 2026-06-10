class SuperAdmin::TeamsController < SuperAdmin::BaseController
  before_action :set_team, only: [:show, :edit, :update, :destroy]

  def index
    skip_policy_scope
    @pagy, @teams = pagy(Team.by_name.includes(:created_by))
  end

  def show
    authorize @team
  end

  def new
    @team = Team.new
    authorize @team
  end

  def create
    @team = Team.new(team_params.merge(created_by: current_user))
    authorize @team
    if @team.save
      redirect_to super_admin_team_path(@team), notice: t("super_admin.teams.created")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @team
  end

  def update
    authorize @team
    if @team.update(team_params)
      redirect_to super_admin_team_path(@team), notice: t("super_admin.teams.updated")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @team
    @team.destroy!
    redirect_to super_admin_teams_path, notice: t("super_admin.teams.destroyed")
  end

  private

  def set_team
    @team = Team.find(params[:id])
  end

  def team_params
    params.require(:team).permit(:name, :short_name, :country_code, :logo)
  end
end
