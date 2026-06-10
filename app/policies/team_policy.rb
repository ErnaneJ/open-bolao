class TeamPolicy < ApplicationPolicy
  def index?  = true
  def show?   = true
  def create? = admin? || super_admin?
  def update? = super_admin?
  def destroy? = super_admin?
  def search? = admin? || super_admin?

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.all
    end
  end
end
