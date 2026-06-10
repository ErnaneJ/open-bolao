class TipsController < ApplicationController
  before_action :set_pool

  def index
    skip_authorization
    @tips = current_user.tips.where(pool: @pool).includes(:match)
    @matches_with_tips = build_matches_with_tips
  end

  def create
    @tip = @pool.tips.find_or_initialize_by(user_id: current_user.id, match_id: tip_params[:match_id])
    authorize @tip
    @tip.assign_attributes(tip_params)
    if @tip.save
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("tip_#{@tip.match_id}", partial: "tips/tip", locals: { tip: @tip, pool: @pool }) }
        format.html { redirect_to pool_path(@pool) }
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    @tip = @pool.tips.find_by!(user_id: current_user.id, match_id: params[:id])
    authorize @tip
    if @tip.update(tip_params)
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("tip_#{@tip.match_id}", partial: "tips/tip", locals: { tip: @tip, pool: @pool }) }
        format.html { redirect_to pool_path(@pool) }
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_pool
    @pool = Pool.friendly.find(params[:pool_id])
  end

  def tip_params
    params.require(:tip).permit(:match_id, :home_score_tip, :away_score_tip)
  end

  def build_matches_with_tips
    matches = if @pool.tournament_pool?
                @pool.tournament.matches.includes(:home_team, :away_team, :stage).order(:scheduled_at)
              else
                [@pool.match]
              end
    tip_map = @tips.index_by(&:match_id)
    matches.map { |m| [m, tip_map[m.id]] }
  end
end
