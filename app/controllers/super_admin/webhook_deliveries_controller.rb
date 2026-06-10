class SuperAdmin::WebhookDeliveriesController < SuperAdmin::BaseController
  before_action :set_endpoint

  def index
    skip_authorization
    @pagy, @deliveries = pagy(@endpoint.webhook_deliveries.recent, items: 30)
  end

  def show
    skip_authorization
    @delivery = @endpoint.webhook_deliveries.find(params[:id])
  end

  private

  def set_endpoint
    @endpoint = WebhookEndpoint.find(params[:webhook_endpoint_id])
  end
end
