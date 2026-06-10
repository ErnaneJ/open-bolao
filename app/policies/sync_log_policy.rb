class SyncLogPolicy < ApplicationPolicy
  def index? = admin_of_schedule? || super_admin?
  def show?  = admin_of_schedule? || super_admin?

  class Scope < ApplicationPolicy::Scope
    def resolve
      super_admin? ? scope.all : scope.none
    end
  end

  private

  def admin_of_schedule?
    SyncSchedulePolicy.new(user, record.sync_schedule).show?
  end
end
