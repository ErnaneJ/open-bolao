class WebhookEndpointPolicy < ApplicationPolicy
  def index?   = owner? || super_admin?
  def show?    = owner? || super_admin?
  def create?  = owner? || super_admin?
  def update?  = owner? || super_admin?
  def destroy? = owner? || super_admin?
  def test?    = owner? || super_admin?

  class Scope < ApplicationPolicy::Scope
    def resolve
      if super_admin?
        scope.all
      else
        scope.where(owner: user)
             .or(scope.where(owner: user.administered_pools))
      end
    end
  end

  private

  def owner?
    case record.owner
    when User then record.owner_id == user.id
    when Pool then record.owner.admin_id == user.id
    else false
    end
  end
end
