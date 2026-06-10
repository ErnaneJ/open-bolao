class RankingChannel < ApplicationCable::Channel
  def subscribed
    pool = Pool.find_by(id: params[:pool_id])
    if pool
      stream_from "ranking_pool_#{pool.id}"
    else
      reject
    end
  end

  def unsubscribed; end
end
