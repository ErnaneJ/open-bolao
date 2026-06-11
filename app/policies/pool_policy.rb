class PoolPolicy < ApplicationPolicy
  def index?  = true
  def show?   = user.present? && (participant? || admin_owner? || super_admin?)
  def manage? = admin_owner? || super_admin?
  def create? = user.present?
  def update? = admin_owner? || super_admin?
  def destroy? = admin_owner? || super_admin?
  def join?   = user.present? && !participant?
  def leave?  = participant? && !record.competition_started?
  def recalculate? = admin_owner? || super_admin?
  def transition?  = admin_owner? || super_admin?

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.all if super_admin?
      participating = PoolParticipant.active.where(user_id: user.id).select(:pool_id)
      scope.where(admin_id: user.id).or(scope.where(id: participating))
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
