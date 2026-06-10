class SuperAdmin::SettingsController < SuperAdmin::BaseController
  def show
    skip_authorization
    @settings = {
      app_name: ENV.fetch("APP_NAME", "Bolão"),
      app_host: ENV.fetch("APP_HOST", "localhost:3000"),
      default_locale: I18n.default_locale,
      sidekiq_url: super_admin_sidekiq_web_path,
      blazer_url: super_admin_blazer_path
    }
  end

  def update
    skip_authorization
    redirect_to super_admin_settings_path, notice: t("super_admin.settings.updated")
  end
end
