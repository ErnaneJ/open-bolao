class SuperAdmin::ApiProvidersController < SuperAdmin::BaseController
  before_action :set_provider, only: [:show, :edit, :update, :destroy, :test_connection]

  def index
    skip_policy_scope
    @providers = ApiProvider.all
    skip_authorization
  end

  def show
    skip_authorization
  end

  def new
    @provider = ApiProvider.new
    skip_authorization
  end

  def create
    @provider = ApiProvider.new(provider_params)
    skip_authorization
    if @provider.save
      redirect_to super_admin_api_provider_path(@provider), notice: t("super_admin.api_providers.created")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    skip_authorization
  end

  def update
    skip_authorization
    if @provider.update(provider_params)
      redirect_to super_admin_api_provider_path(@provider), notice: t("super_admin.api_providers.updated")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    skip_authorization
    @provider.destroy!
    redirect_to super_admin_api_providers_path, notice: t("super_admin.api_providers.destroyed")
  end

  def test_connection
    skip_authorization
    adapter = ApiProviders::Worldcup2026Adapter.new(@provider)
    teams = adapter.fetch_teams
    if teams.any?
      redirect_to super_admin_api_providers_path, notice: t("super_admin.api_providers.connection_ok", count: teams.size)
    else
      redirect_to super_admin_api_providers_path, alert: t("super_admin.api_providers.connection_empty")
    end
  rescue => e
    redirect_to super_admin_api_providers_path, alert: t("super_admin.api_providers.connection_failed", error: e.message)
  end

  private

  def set_provider
    @provider = ApiProvider.find(params[:id])
  end

  def provider_params
    params.require(:api_provider).permit(:name, :provider_type, :base_url, :active, config: {})
  end
end
