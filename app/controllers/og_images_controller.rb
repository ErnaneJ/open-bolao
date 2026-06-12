class OgImagesController < ApplicationController
  skip_before_action :authenticate_user!
  skip_before_action :verify_authenticity_token

  def home
    png = OgImageService.home
    send_data png, type: "image/png", disposition: "inline"
  end

  def pool
    @pool = Pool.friendly.find(params[:slug])
    png = OgImageService.pool(@pool)
    send_data png, type: "image/png", disposition: "inline"
  rescue ActiveRecord::RecordNotFound
    redirect_to og_home_path
  end

  def match
    @match = Match.includes(:home_team, :away_team, :stage, :tournament).find(params[:id])
    png = OgImageService.match(@match)
    send_data png, type: "image/png", disposition: "inline"
  rescue ActiveRecord::RecordNotFound
    redirect_to og_home_path
  end
end
