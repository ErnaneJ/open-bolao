class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index?    = false
  def show?     = false
  def create?   = false
  def new?      = create?
  def update?   = false
  def edit?     = update?
  def destroy?  = false

  protected

  def super_admin? = user&.role_super_admin?
  def admin?       = user&.role_admin? || super_admin?

  class Scope
    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      raise NoMethodError, "You must define #resolve in #{self.class}"
    end

    private

    attr_reader :user, :scope

    def super_admin? = user&.role_super_admin?
    def admin?       = user&.role_admin? || super_admin?
  end
end
