class Admin::LineupController < Admin::BaseController
  before_action :set_pool

  def index
    skip_authorization
    @pool_matches = @pool.pool_matches.includes(match: [ :home_team, :away_team, :stage ])
                         .order("matches.scheduled_at ASC")
    @available_matches = available_matches_for_import
  end

  def create
    skip_authorization
    match = Match.find(params[:match_id])
    pm = @pool.pool_matches.find_or_initialize_by(match: match)
    if pm.new_record? && pm.save
      redirect_to admin_pool_lineup_index_path(@pool), notice: "Jogo adicionado ao bolão."
    else
      redirect_to admin_pool_lineup_index_path(@pool), alert: "Jogo já está no bolão."
    end
  end

  def destroy
    skip_authorization
    @pool.pool_matches.find(params[:id]).destroy!
    redirect_to admin_pool_lineup_index_path(@pool), notice: "Jogo removido do bolão."
  end

  # Import all matches from the linked tournament
  def import_tournament
    skip_authorization
    return redirect_to(admin_pool_lineup_index_path(@pool), alert: "Bolão não tem torneio.") unless @pool.tournament

    imported = 0
    @pool.tournament.matches.each do |match|
      pm = @pool.pool_matches.find_or_initialize_by(match: match)
      imported += 1 if pm.new_record? && pm.save
    end
    redirect_to admin_pool_lineup_index_path(@pool), notice: "#{imported} jogos importados do torneio."
  end

  # Import from Copa 2026 API (fetches and upserts into tournament, then adds to pool)
  def import_api
    skip_authorization
    return redirect_to(admin_pool_lineup_index_path(@pool), alert: "Bolão precisa ter um torneio associado.") unless @pool.tournament

    adapter = ApiProviders::Worldcup2026Adapter.new
    results = adapter.fetch_matches
    imported = 0

    results.each do |md|
      home_team = Team.find_by("name ILIKE ?", md.home_team_name)
      away_team = Team.find_by("name ILIKE ?", md.away_team_name)
      next unless home_team && away_team

      match = Match.find_or_initialize_by(external_id: md.external_id, tournament: @pool.tournament)
      match.assign_attributes(
        home_team: home_team, away_team: away_team,
        scheduled_at: md.scheduled_at, status: md.status || :scheduled,
        home_score: md.home_score, away_score: md.away_score
      )
      match.save!

      pm = @pool.pool_matches.find_or_initialize_by(match: match)
      imported += 1 if pm.new_record? && pm.save
    end

    redirect_to admin_pool_lineup_index_path(@pool), notice: "#{imported} jogos sincronizados da API."
  rescue => e
    redirect_to admin_pool_lineup_index_path(@pool), alert: "Erro na API: #{e.message}"
  end

  private

  def set_pool
    @pool = current_user.administered_pools.friendly.find(params[:pool_id])
  rescue ActiveRecord::RecordNotFound
    @pool = Pool.friendly.find(params[:pool_id]) if current_user.role_super_admin?
    redirect_to admin_pools_path, alert: t("errors.not_authorized") unless @pool
  end

  def available_matches_for_import
    return Match.none unless @pool.tournament
    already_added = @pool.pool_matches.pluck(:match_id)
    @pool.tournament.matches
         .where.not(id: already_added)
         .includes(:home_team, :away_team, :stage)
         .order(:scheduled_at)
         .limit(50)
  end
end
