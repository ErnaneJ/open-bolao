email    = ENV.fetch("SEED_ADMIN_EMAIL", "admin@bolao.local")
password = ENV.fetch("SEED_ADMIN_PASSWORD", "changeme123!")

user = User.find_or_initialize_by(email: email)
user.assign_attributes(
  name: "Super Admin",
  password: password,
  password_confirmation: password,
  role: :super_admin,
  locale: :pt_br,
  confirmed_at: Time.current
)
user.save!
puts "Super admin: #{user.email}"
