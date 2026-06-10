class MatchPolicy < ApplicationPolicy
  def index?  = true
  def show?   = true
  def create? = admin? || super_admin?
  def update? = admin_of_pool_for_match? || super_admin?
  def destroy? = super_admin?

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.all
    end
  end

  private

  def admin_of_pool_for_match?
    user.role_admin? && record.tournament&.pools&.exists?(admin_id: user.id)
  end
end
