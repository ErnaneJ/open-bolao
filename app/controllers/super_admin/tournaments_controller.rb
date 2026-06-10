class SuperAdmin::TournamentsController < SuperAdmin::BaseController
  include Pagy::Backend
  before_action :set_tournament, only: [:show, :edit, :update, :destroy, :sync, :seed_from_api]

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

  def sync
    authorize @tournament
    Sync::FetchResultsJob.perform_later(@tournament.id, "Tournament")
    redirect_to super_admin_tournament_path(@tournament), notice: t("super_admin.tournaments.sync_queued")
  end

  def seed_from_api
    authorize @tournament
    # Enqueues a seeding job to populate teams/matches from the API
    Sync::SeedFromApiJob.perform_later(@tournament.id)
    redirect_to super_admin_tournament_path(@tournament), notice: t("super_admin.tournaments.seed_queued")
  end

  private

  def set_tournament
    @tournament = Tournament.friendly.find(params[:id])
  end

  def tournament_params
    params.require(:tournament).permit(
      :name, :sport, :season, :status, :external_provider, :logo,
      external_config: {}
    )
  end
end
