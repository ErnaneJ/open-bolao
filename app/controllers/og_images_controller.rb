class OgImagesController < ApplicationController
  skip_before_action :authenticate_user!
  skip_before_action :verify_authenticity_token

  before_action :set_cache_headers

  def home
    render layout: false, content_type: "image/svg+xml"
  end

  def pool
    @pool = Pool.friendly.find(params[:slug])
    render layout: false, content_type: "image/svg+xml"
  rescue ActiveRecord::RecordNotFound
    render layout: false, content_type: "image/svg+xml", template: "og_images/home"
  end

  def match
    @match = Match.includes(:home_team, :away_team, :stage, :tournament).find(params[:id])
    render layout: false, content_type: "image/svg+xml"
  rescue ActiveRecord::RecordNotFound
    render layout: false, content_type: "image/svg+xml", template: "og_images/home"
  end

  private

  def set_cache_headers
    expires_in 10.minutes, public: true
  end
end
