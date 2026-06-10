class Admin::TeamsController < Admin::BaseController
  def new
    @team = Team.new
    authorize @team
  end

  def create
    @team = Team.new(team_params.merge(created_by: current_user))
    authorize @team
    if @team.save
      respond_to do |format|
        format.json { render json: { id: @team.id, name: @team.name } }
        format.html { redirect_to new_admin_match_path, notice: t("admin.teams.created") }
      end
    else
      respond_to do |format|
        format.json { render json: { errors: @team.errors.full_messages }, status: :unprocessable_entity }
        format.html { render :new, status: :unprocessable_entity }
      end
    end
  end

  def search
    skip_authorization
    @teams = Team.search_by_name(params[:q]).by_name.limit(10)
    render json: @teams.map { |t| { id: t.id, name: t.name, country_code: t.country_code } }
  end

  private

  def team_params
    params.require(:team).permit(:name, :short_name, :country_code, :logo)
  end
end
