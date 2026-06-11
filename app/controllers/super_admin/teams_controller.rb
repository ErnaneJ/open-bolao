class SuperAdmin::TeamsController < SuperAdmin::BaseController
  before_action :set_team, only: [:show, :edit, :update, :destroy]

  def index
    skip_policy_scope
    base = Team.includes(:tournament_teams)
    base = base.where("name ILIKE :q OR short_name ILIKE :q", q: "%#{params[:q]}%") if params[:q].present?
    @pagy, @teams = pagy(base.order(:name), items: 100)
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
    matches_count = @team.home_matches.count + @team.away_matches.count
    if matches_count > 0
      return redirect_to super_admin_teams_path,
             alert: "Não é possível excluir #{@team.name}: este time possui #{matches_count} jogo(s) cadastrado(s). Exclua os jogos primeiro ou importe o torneio novamente."
    end
    @team.destroy!
    redirect_to super_admin_teams_path, notice: t("super_admin.teams.destroyed")
  rescue ActiveRecord::DeleteRestrictionError => e
    redirect_to super_admin_teams_path,
                alert: "Não é possível excluir #{@team.name}: ele ainda possui jogos associados. Remova os jogos primeiro."
  end

  def batch_destroy
    skip_authorization
    ids = Array(params[:ids]).map(&:to_i).reject(&:zero?)
    return redirect_to super_admin_teams_path, alert: "Nenhum time selecionado." if ids.empty?

    destroyed = 0
    blocked   = 0
    Team.where(id: ids).each do |team|
      next if team.home_matches.exists? || team.away_matches.exists?
      team.destroy!
      destroyed += 1
    rescue ActiveRecord::DeleteRestrictionError
      blocked += 1
    end

    msg = "#{destroyed} time(s) excluído(s)."
    msg += " #{blocked} não pôde(ram) ser excluído(s) por terem jogos associados." if blocked > 0
    redirect_to super_admin_teams_path, notice: msg
  end

  # POST /super_admin/teams/import_from_tsdb
  # Accepts: numeric ID, "134299-atletico-mineiro", or plain name "Atletico Mineiro"
  def import_from_tsdb
    authorize Team.new, :create?
    identifier = params[:tsdb_id].to_s.strip

    if identifier.blank?
      return redirect_to super_admin_teams_path, alert: "Informe um ID ou nome de time."
    end

    adapter = ApiProviders::ThesportsdbAdapter.new
    td = resolve_team(adapter, identifier)

    if td.nil?
      return redirect_to super_admin_teams_path,
             alert: "Time \"#{identifier}\" não encontrado no TheSportsDB. Tente o nome em inglês (ex: Atletico Mineiro)."
    end

    team = Team.find_by(external_provider_id: td.external_tsdb_id, external_provider_name: "thesportsdb") ||
           Team.find_by("name ILIKE ?", td.name) ||
           Team.new(created_by: current_user)

    team.assign_attributes(
      name:                   td.name,
      short_name:             td.short_name,
      country_code:           td.country_code,
      logo_url:               td.logo_url.presence || team.logo_url,
      banner_url:             td.banner_url.presence || team.banner_url,
      fanart_url:             td.fanart_url.presence || team.fanart_url,
      primary_color:          td.primary_color.presence || team.primary_color,
      formed_year:            td.formed_year || team.formed_year,
      stadium_name:           td.stadium_name.presence || team.stadium_name,
      description:            td.description.presence || team.description,
      website:                td.website.presence || team.website,
      gender:                 td.gender.presence || team.gender,
      external_provider_id:   td.external_tsdb_id,
      external_provider_name: "thesportsdb"
    )

    if team.save
      redirect_to super_admin_teams_path, notice: "#{team.name} (ID #{td.external_tsdb_id}) importado com sucesso."
    else
      redirect_to super_admin_teams_path, alert: "Erro: #{team.errors.full_messages.to_sentence}"
    end
  end

  private

  # Tries ID lookup first, then falls back to name search.
  def resolve_team(adapter, identifier)
    numeric_id = identifier.match(/^(\d+)/)[1] rescue nil

    if numeric_id.present?
      td = adapter.fetch_team(numeric_id)
      return td if td
    end

    # Fall back: search by the text portion, replacing hyphens with spaces
    query = identifier.sub(/^\d+[-\s]*/, "").presence || identifier
    query = query.gsub("-", " ").strip
    results = adapter.search_teams(query)
    results.first
  end

  def set_team
    @team = Team.find(params[:id])
  end

  def team_params
    params.require(:team).permit(
      :name, :short_name, :country_code, :flag_url, :logo,
      :logo_url, :banner_url, :fanart_url,
      :primary_color, :formed_year, :stadium_name, :description, :website, :gender,
      :external_provider_id, :external_provider_name
    )
  end
end
