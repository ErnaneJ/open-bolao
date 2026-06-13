class PoolsController < ApplicationController
  before_action :set_pool, only: [ :show, :join, :leave, :match_panel, :recalculate_ranking ]

  def index
    skip_policy_scope
    @pagy, @pools = pagy(
      policy_scope(Pool).includes(:admin, :tournament).order(created_at: :desc)
    )
  end

  def show
    authorize @pool
    @participant = @pool.pool_participants.find_by(user_id: current_user.id)
    @pagy_ranking, @ranking = pagy(
      @pool.pool_participants.active.includes(:user)
           .order(Arel.sql("rank ASC NULLS LAST, total_points DESC")),
      items: 50
    )
    @matches = pool_matches
    @tips_map = current_user.tips.where(pool: @pool).index_by(&:match_id)

    # For the tips tab: count of participants who tipped per match,
    # and actual tips for matches that have already started (locked)
    started_match_ids = @matches.select { |m| @pool.tips_locked_for?(m) }.map(&:id)
    @participant_tips_by_match = @pool.tips
      .where(match_id: started_match_ids)
      .includes(:user)
      .group_by(&:match_id)
    @tip_counts_by_match = @pool.tips.where(match_id: @matches.map(&:id))
      .group(:match_id).count
  end

  def join
    authorize @pool
    participant = @pool.pool_participants.find_or_initialize_by(user_id: current_user.id)
    if participant.new_record?
      participant.status = :active
      participant.save!
      Rankings::UpdatePoolRankingJob.perform_later(@pool.id)
      redirect_to pool_path(@pool), notice: t("pools.joined")
    else
      redirect_to pool_path(@pool), alert: t("pools.already_joined")
    end
  end

  def leave
    authorize @pool
    if @pool.competition_started?
      redirect_to pool_path(@pool), alert: t("pools.cannot_leave_started")
      return
    end
    participant = @pool.pool_participants.find_by!(user_id: current_user.id)
    participant.destroy!
    redirect_to pools_path, notice: t("pools.left")
  end

  # GET /join/:invite_code — preview page before accepting
  def join_by_code
    @pool = Pool.find_by(invite_code: params[:invite_code].upcase)
    if @pool.nil?
      redirect_to pools_path, alert: t("pools.invalid_invite_code")
    elsif @pool.pool_participants.active.exists?(user_id: current_user.id)
      redirect_to pool_path(@pool), notice: t("pools.already_joined")
    end
  end

  # POST /join/:invite_code — accept and join
  def accept_invite
    @pool = Pool.find_by(invite_code: params[:invite_code].upcase)
    if @pool.nil?
      redirect_to dashboard_path, alert: t("pools.invalid_invite_code")
      return
    end
    participant = @pool.pool_participants.find_or_initialize_by(user_id: current_user.id)
    if participant.new_record?
      participant.status = :active
      participant.save!
      Rankings::UpdatePoolRankingJob.perform_later(@pool.id)
      redirect_to pool_path(@pool), notice: t("pools.joined")
    else
      redirect_to pool_path(@pool), alert: t("pools.already_joined")
    end
  end

  def recalculate_ranking
    authorize @pool, :manage?
    @pool.tips.includes(:match).find_each do |tip|
      Tips::ScoringService.call(tip: tip, match: tip.match, pool: @pool) if tip.match.status_finished?
    end
    @ranking = Rankings::UpdatePoolRankingService.call(pool: @pool)
    @ranking = @pool.pool_participants.active.includes(:user)
                    .order(Arel.sql("rank ASC NULLS LAST, total_points DESC"))
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.replace("ranking-table",
            partial: "pools/ranking",
            locals: { pool: @pool, ranking: @ranking, pagy: nil }),
          turbo_stream.replace("flash-container",
            partial: "shared/flash",
            locals: { notice: "Ranking atualizado!", alert: nil })
        ]
      end
      format.html { redirect_to pool_path(@pool), notice: "Ranking atualizado!" }
    end
  end

  # GET /pools/:id/match_panel?match_id=:match_id
  def match_panel
    authorize @pool, :show?
    @match = @pool.active_matches.find(params[:match_id])
    @is_locked = @pool.tips_locked_for?(@match)
    @my_tip = current_user.tips.find_by(pool: @pool, match_id: @match.id)
    @participant_tips = @pool.tips.where(match_id: @match.id).includes(:user)
      .joins(:user).order("pool_participants.rank ASC NULLS LAST")
      .joins("LEFT JOIN pool_participants ON pool_participants.pool_id = tips.pool_id AND pool_participants.user_id = tips.user_id")
    render partial: "pools/match_panel"
  end

  private

  def set_pool
    @pool = Pool.friendly.find(params[:id])
  end

  def pool_matches
    @pool.active_matches
  end
end
