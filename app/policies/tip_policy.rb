class TipPolicy < ApplicationPolicy
  def index?  = participant_in_pool?
  def create? = participant_in_pool? && !record.locked?
  def update? = participant_in_pool? && record.user_id == user.id && !record.locked?

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.where(user_id: user.id)
    end
  end

  private

  def participant_in_pool?
    record.pool.pool_participants.active.exists?(user_id: user.id)
  end
end
