class SyncSchedulePolicy < ApplicationPolicy
  def show?       = admin_of_schedulable? || super_admin?
  def update?     = admin_of_schedulable? || super_admin?
  def force_run?  = admin_of_schedulable? || super_admin?

  class Scope < ApplicationPolicy::Scope
    def resolve
      super_admin? ? scope.all : scope.none
    end
  end

  private

  def admin_of_schedulable?
    return false unless user.role_admin?
    case record.schedulable
    when Tournament
      record.schedulable.pools.exists?(admin_id: user.id)
    else
      false
    end
  end
end
