class SuperAdmin::MatchesController < SuperAdmin::BaseController
  before_action :set_match, only: [:show, :edit, :update, :destroy]

  def index
    skip_policy_scope
    base = Match.includes(:home_team, :away_team, :stage, :tournament)
    if params[:q].present?
      base = base
        .joins("INNER JOIN teams ht ON matches.home_team_id = ht.id")
        .joins("INNER JOIN teams at ON matches.away_team_id = at.id")
        .where("ht.name ILIKE :q OR at.name ILIKE :q", q: "%#{params[:q]}%")
    end
    base = base.where(tournament_id: params[:tournament_id]) if params[:tournament_id].present?
    @pagy, @matches = pagy(base.order(scheduled_at: :desc), items: 50)
  end

  def show
    authorize @match
  end

  def edit
    authorize @match
    @teams       = Team.by_name
    @tournaments = Tournament.order(:name)
    @stages      = @match.tournament ? @match.tournament.stages.order(:order_position) : Stage.order(:name)
    render layout: "admin_fullscreen"
  end

  def update
    authorize @match
    was_finished = @match.status_finished?
    if @match.update(match_params)
      if @match.status_finished? && !was_finished
        Matches::RecalculateTipsJob.perform_later(@match.id)
      end
      redirect_to super_admin_match_path(@match), notice: t("super_admin.matches.updated")
    else
      @teams       = Team.by_name
      @tournaments = Tournament.order(:name)
      @stages      = @match.tournament ? @match.tournament.stages.order(:order_position) : Stage.order(:name)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @match
    name = "#{@match.home_team.name} × #{@match.away_team.name}"
    @match.destroy!
    redirect_to super_admin_matches_path, notice: "Jogo #{name} excluído."
  end

  def batch_destroy
    skip_authorization
    ids = Array(params[:ids]).map(&:to_i).reject(&:zero?)
    return redirect_to super_admin_matches_path, alert: "Nenhum jogo selecionado." if ids.empty?

    count = Match.where(id: ids).destroy_all.size
    redirect_to super_admin_matches_path, notice: "#{count} jogo(s) excluído(s)."
  end

  # POST /super_admin/matches/import_from_tsdb
  def import_from_tsdb
    authorize Match.new, :create?
    identifier = params[:tsdb_id].to_s.strip
    event_id   = identifier.match(/^(\d+)/)[1] rescue nil

    if event_id.blank?
      return redirect_to super_admin_matches_path, alert: "ID inválido. Use o formato: 2398371-atletico-vs-bahia"
    end

    adapter = ApiProviders::ThesportsdbAdapter.new
    md = adapter.fetch_match(event_id)

    if md.nil?
      return redirect_to super_admin_matches_path, alert: "Jogo #{identifier} não encontrado no TheSportsDB."
    end

    # Resolve home team
    home_team = find_or_import_team(adapter, md.home_team_external_id, md.home_team_name)
    away_team = find_or_import_team(adapter, md.away_team_external_id, md.away_team_name)

    unless home_team && away_team
      missing = [home_team ? nil : md.home_team_name, away_team ? nil : md.away_team_name].compact.join(", ")
      return redirect_to super_admin_matches_path,
             alert: "Não foi possível importar os times: #{missing}. Verifique os IDs no TheSportsDB."
    end

    match = Match.find_or_initialize_by(external_tsdb_id: event_id, external_provider_name: "thesportsdb")
    match.assign_attributes(
      home_team:              home_team,
      away_team:              away_team,
      scheduled_at:           md.scheduled_at,
      status:                 md.status || :scheduled,
      home_score:             md.home_score,
      away_score:             md.away_score,
      venue:                  md.stadium_name,
      thumb_url:              md.thumb_url,
      stream_url:             md.stream_url.presence,
      external_id:            event_id,
      external_provider_name: "thesportsdb"
    )

    if match.save
      redirect_to super_admin_matches_path, notice: "Jogo #{md.home_team_name} × #{md.away_team_name} importado."
    else
      redirect_to super_admin_matches_path, alert: "Erro: #{match.errors.full_messages.to_sentence}"
    end
  end

  private

  def find_or_import_team(adapter, tsdb_id, name)
    # 1. Already in DB
    team = Team.find_by(external_provider_id: tsdb_id, external_provider_name: "thesportsdb") if tsdb_id.present?
    team ||= Team.find_by("name ILIKE ?", name)
    return team if team

    # 2. Fetch from TSDB: by ID first, then by name search (normalise hyphens → spaces)
    td = tsdb_id.present? ? adapter.fetch_team(tsdb_id) : nil
    td ||= adapter.search_teams(name.gsub("-", " ")).first

    return nil unless td

    t = Team.find_or_initialize_by(external_provider_id: td.external_tsdb_id, external_provider_name: "thesportsdb")
    t.assign_attributes(
      name:         td.name,
      short_name:   td.short_name,
      country_code: td.country_code,
      created_by:   current_user
    )
    t.save ? t : nil
  end

  def set_match
    @match = Match.find(params[:id])
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
end
