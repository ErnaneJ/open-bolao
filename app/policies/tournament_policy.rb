class TournamentPolicy < ApplicationPolicy
  def index?  = true
  def show?   = true
  def create? = super_admin?
  def update? = super_admin?
  def destroy? = super_admin?
  def sync?           = super_admin?
  def seed_from_api?  = super_admin?
  def import_teams?   = super_admin?
  def import_matches? = super_admin?

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.all
    end
  end
end
