class PoolPolicy < ApplicationPolicy
  def index?  = true
  def show?   = user.present? && (participant? || admin_owner? || super_admin?)
  def create? = admin? || super_admin?
  def update? = admin_owner? || super_admin?
  def destroy? = admin_owner? || super_admin?
  def join?   = user.present? && !participant?
  def leave?  = participant? && !record.competition_started?
  def recalculate? = admin_owner? || super_admin?
  def transition?  = admin_owner? || super_admin?

  class Scope < ApplicationPolicy::Scope
    def resolve
      if super_admin?
        scope.all
      elsif admin?
        scope.where(admin_id: user.id)
             .or(scope.joins(:pool_participants).where(pool_participants: { user_id: user.id, status: :active }))
      else
        scope.joins(:pool_participants)
             .where(pool_participants: { user_id: user.id, status: :active })
      end
    end
  end

  private

  def participant?
    record.pool_participants.active.exists?(user_id: user.id)
  end

  def admin_owner?
    record.admin_id == user.id
  end
end
