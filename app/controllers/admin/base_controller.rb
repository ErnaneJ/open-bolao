class Admin::BaseController < ApplicationController
  layout "admin"
  # Any authenticated user can access the admin area for their own pools.
  # Pundit policies enforce per-resource authorization.
  before_action :authenticate_user!
end
