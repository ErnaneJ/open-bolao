class UserPolicy < ApplicationPolicy
  def index?      = super_admin?
  def show?       = user.id == record.id || super_admin?
  def update?     = user.id == record.id || super_admin?
  def destroy?    = super_admin?
  def impersonate? = super_admin?
  def ban?        = super_admin?

  class Scope < ApplicationPolicy::Scope
    def resolve
      super_admin? ? scope.all : scope.where(id: user.id)
    end
  end
end
