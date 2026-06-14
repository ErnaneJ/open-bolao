class SuperAdmin::UsersController < SuperAdmin::BaseController
  include Pagy::Backend
  before_action :set_user, only: [ :show, :edit, :update, :destroy, :impersonate, :ban ]

  def index
    skip_policy_scope
    @pagy, @users = pagy(User.by_name.includes(:pool_participants))
  end

  def show
    authorize @user
  end

  def edit
    authorize @user
  end

  def update
    authorize @user
    if @user.update(user_params)
      redirect_to super_admin_user_path(@user), notice: t("super_admin.users.updated")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @user
    @user.destroy!
    redirect_to super_admin_users_path, notice: t("super_admin.users.destroyed")
  end

  def impersonate
    authorize @user
    sign_in(:user, @user)
    redirect_to dashboard_path, notice: t("super_admin.users.impersonating", name: @user.display_name)
  end

  def ban
    authorize @user
    @user.update!(role: :user)
    redirect_to super_admin_user_path(@user), notice: t("super_admin.users.banned")
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    p = params.require(:user).permit(:name, :email, :role, :locale, :password, :password_confirmation)
    if p[:password].blank?
      p.delete(:password)
      p.delete(:password_confirmation)
    end
    p
  end
end
