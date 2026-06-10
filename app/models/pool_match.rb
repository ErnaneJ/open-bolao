class PoolMatch < ApplicationRecord
  belongs_to :pool
  belongs_to :match

  validates :match_id, uniqueness: { scope: :pool_id }
end
