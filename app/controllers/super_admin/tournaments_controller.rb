class SuperAdmin::TournamentsController < SuperAdmin::BaseController
  include Pagy::Backend
  before_action :set_tournament, only: [:show, :edit, :update, :destroy, :sync, :seed_from_api, :import_teams, :import_matches]

  def index
    skip_policy_scope
    @pagy, @tournaments = pagy(Tournament.by_season.includes(:created_by))
  end

  def show
    authorize @tournament
  end

  def new
    @tournament = Tournament.new
    authorize @tournament
  end

  def create
    @tournament = current_user.created_tournaments.build(tournament_params)
    authorize @tournament
    if @tournament.save
      redirect_to super_admin_tournament_path(@tournament), notice: t("super_admin.tournaments.created")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @tournament
  end

  def update
    authorize @tournament
    if @tournament.update(tournament_params)
      redirect_to super_admin_tournament_path(@tournament), notice: t("super_admin.tournaments.updated")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @tournament
    @tournament.destroy!
    redirect_to super_admin_tournaments_path, notice: t("super_admin.tournaments.destroyed")
  end

  # Sync current scores only (does NOT import new matches/teams)
  def sync
    authorize @tournament
    Sync::FetchResultsJob.perform_later(@tournament.id, "Tournament")
    redirect_to super_admin_tournament_path(@tournament), notice: "Sync de placares enfileirado no Sidekiq."
  end

  # Full re-import from TheSportsDB (new teams + new matches + score updates)
  def seed_from_api
    authorize @tournament
    league_id = @tournament.external_config&.dig("tsdb_league_id")
    season    = @tournament.season || Time.current.year.to_s

    unless league_id.present?
      return redirect_to super_admin_tournament_path(@tournament),
             alert: "Este torneio não tem ID do TheSportsDB configurado. Edite e adicione o tsdb_league_id."
    end

    # Clear partial data synchronously (fast) before the async re-import
    @tournament.matches.delete_all
    @tournament.stages.delete_all

    Sync::ImportTournamentFromTsdbJob.perform_later(
      league_id:     league_id,
      season:        season,
      created_by_id: current_user.id
    )

    redirect_to super_admin_tournament_path(@tournament),
                notice: "Re-import enfileirado no Sidekiq. Atualize a página em alguns minutos para ver os dados."
  rescue => e
    redirect_to super_admin_tournament_path(@tournament), alert: "Erro ao enfileirar: #{e.message}"
  end

  # POST — import only teams
  def import_teams
    authorize @tournament
    league_id = @tournament.external_config&.dig("tsdb_league_id")
    return redirect_to super_admin_tournament_path(@tournament),
           alert: "Torneio sem tsdb_league_id configurado." unless league_id.present?

    Sync::ImportTournamentTeamsJob.perform_later(
      tournament_id:  @tournament.id,
      league_id:      league_id,
      created_by_id:  current_user.id
    )
    redirect_to super_admin_tournament_path(@tournament),
                notice: "Import de times enfileirado. Aguarde alguns minutos."
  rescue => e
    redirect_to super_admin_tournament_path(@tournament), alert: "Erro: #{e.message}"
  end

  # POST — import only matches
  def import_matches
    authorize @tournament
    league_id = @tournament.external_config&.dig("tsdb_league_id")
    season    = @tournament.season || Time.current.year.to_s
    return redirect_to super_admin_tournament_path(@tournament),
           alert: "Torneio sem tsdb_league_id configurado." unless league_id.present?

    Sync::ImportTournamentMatchesJob.perform_later(
      tournament_id:  @tournament.id,
      league_id:      league_id,
      season:         season,
      created_by_id:  current_user.id
    )
    redirect_to super_admin_tournament_path(@tournament),
                notice: "Import de jogos enfileirado. Aguarde alguns minutos."
  rescue => e
    redirect_to super_admin_tournament_path(@tournament), alert: "Erro: #{e.message}"
  end

  # POST /super_admin/tournaments/import_from_tsdb
  # Runs synchronously so the admin sees the result immediately.
  def import_from_tsdb
    authorize Tournament.new, :create?
    identifier = params[:tsdb_id].to_s.strip
    league_id  = identifier.match(/^(\d+)/)[1] rescue nil

    if league_id.blank?
      return redirect_to super_admin_tournaments_path,
             alert: "ID inválido. Use o formato: 4351-nome-do-torneio ou apenas o número."
    end

    season = params[:season].presence || Time.current.year.to_s

    Sync::ImportTournamentFromTsdbJob.perform_later(
      league_id:     league_id,
      season:        season,
      created_by_id: current_user.id
    )

    redirect_to super_admin_tournaments_path,
                notice: "Import da liga #{league_id} (#{season}) enfileirado no Sidekiq. Atualize a página em alguns minutos."
  rescue => e
    redirect_to super_admin_tournaments_path,
                alert: "Erro ao enfileirar: #{e.message}"
  end

  private

  def set_tournament
    @tournament = Tournament.friendly.find(params[:id])
  end

  def tournament_params
    params.require(:tournament).permit(
      :name, :sport, :season, :status, :external_provider, :logo,
      :logo_url, :badge_url, :banner_url, :fanart_url, :trophy_url,
      :country, :description, :gender, :website, :formed_year,
      external_config: {}
    )
  end
end
