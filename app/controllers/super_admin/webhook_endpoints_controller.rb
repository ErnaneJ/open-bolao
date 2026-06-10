class SuperAdmin::WebhookEndpointsController < SuperAdmin::BaseController
  before_action :set_endpoint, only: [:show, :edit, :update, :destroy, :test]

  def index
    skip_policy_scope
    @pagy, @endpoints = pagy(WebhookEndpoint.includes(:owner).order(created_at: :desc))
  end

  def show
    skip_authorization
    @pagy, @deliveries = pagy(@endpoint.webhook_deliveries.recent, items: 20)
  end

  def new
    @endpoint = WebhookEndpoint.new
    skip_authorization
  end

  def create
    @endpoint = WebhookEndpoint.new(endpoint_params.merge(owner_type: "System", owner_id: 0))
    skip_authorization
    if @endpoint.save
      redirect_to super_admin_webhook_endpoint_path(@endpoint), notice: t("super_admin.webhooks.created")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    skip_authorization
  end

  def update
    skip_authorization
    if @endpoint.update(endpoint_params)
      redirect_to super_admin_webhook_endpoint_path(@endpoint), notice: t("super_admin.webhooks.updated")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    skip_authorization
    @endpoint.destroy!
    redirect_to super_admin_webhook_endpoints_path, notice: t("super_admin.webhooks.destroyed")
  end

  def test
    skip_authorization
    Webhooks::DispatchJob.perform_later(event_type: "test", payload: { "message" => "Test from Super Admin" })
    redirect_to super_admin_webhook_endpoints_path, notice: t("super_admin.webhooks.tested")
  end

  private

  def set_endpoint
    @endpoint = WebhookEndpoint.find(params[:id])
  end

  def endpoint_params
    params.require(:webhook_endpoint).permit(:url, :active, events: [])
  end
end
