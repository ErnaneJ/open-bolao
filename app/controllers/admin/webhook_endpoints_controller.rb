class Admin::WebhookEndpointsController < Admin::BaseController
  before_action :set_pool
  before_action :set_endpoint, only: [ :edit, :update, :destroy, :test ]

  def index
    skip_authorization
    @endpoints = @pool.webhook_endpoints.order(created_at: :desc)
  end

  def new
    @endpoint = @pool.webhook_endpoints.build(http_method: "POST")
    skip_authorization
  end

  def create
    @endpoint = @pool.webhook_endpoints.build(endpoint_params)
    skip_authorization
    if @endpoint.save
      redirect_to admin_pool_webhook_endpoints_path(@pool), notice: t("admin.webhooks.created")
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
      redirect_to admin_pool_webhook_endpoints_path(@pool), notice: t("admin.webhooks.updated")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    skip_authorization
    @endpoint.destroy!
    redirect_to admin_pool_webhook_endpoints_path(@pool), notice: t("admin.webhooks.destroyed")
  end

  def test
    skip_authorization
    event_type = params[:event_type].presence || @endpoint.events&.first || "test"
    Webhooks::TestEndpointJob.perform_later(@endpoint.id, event_type)
    redirect_to admin_pool_webhook_endpoints_path(@pool),
                notice: t("admin.webhooks.tested", event: event_type)
  end

  private

  def set_pool
    @pool = if current_user.role_super_admin?
      Pool.friendly.find(params[:pool_id])
    else
      current_user.administered_pools.friendly.find(params[:pool_id])
    end
  end

  def set_endpoint
    @endpoint = @pool.webhook_endpoints.find(params[:id])
  end

  def endpoint_params
    params.require(:webhook_endpoint).permit(:url, :active, :http_method, events: [])
  end
end
