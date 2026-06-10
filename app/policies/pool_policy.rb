class PoolPolicy < ApplicationPolicy
  def index?  = true
  def show?   = user.present? && (record.public_pool? || participant? || admin_owner? || super_admin?)
  def create? = admin? || super_admin?
  def update? = admin_owner? || super_admin?
  def destroy? = admin_owner? || super_admin?
  def join?   = user.present? && !participant?
  def leave?  = participant?
  def recalculate? = admin_owner? || super_admin?
  def transition?  = admin_owner? || super_admin?

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.role_super_admin?
        scope.all
      elsif user.role_admin?
        scope.where(admin_id: user.id).or(scope.where(visibility: :public_pool))
      else
        scope.joins(:pool_participants)
             .where(pool_participants: { user_id: user.id, status: :active })
             .or(scope.where(visibility: :public_pool))
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
