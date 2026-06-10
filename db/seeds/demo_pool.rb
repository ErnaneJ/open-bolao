puts "Seeding demo pools..."

admin_user = User.find_by(role: :super_admin)
tournament = Tournament.find_by(name: "Copa do Mundo 2026")

if tournament
  pool = Pool.find_or_initialize_by(name: "Bolão Copa 2026 - Demo")
  pool.assign_attributes(
    pool_scope: :tournament,
    tournament: tournament,
    admin: admin_user,
    status: :open,
    visibility: :public_pool,
    description: "Bolão demo da Copa do Mundo 2026",
    lock_before_minutes: 5,
    scoring_config: Pool::SCORING_DEFAULTS,
    special_bets_config: Pool::SPECIAL_BETS_DEFAULTS
  )
  pool.save!
  puts "Tournament pool: #{pool.name} (#{pool.invite_code})"
end

# Fallback teams for demo single-match pool when API is unavailable
brasil = Team.find_by("name ILIKE ?", "%brazil%") ||
         Team.find_by("name ILIKE ?", "%brasil%") ||
         Team.find_or_create_by!(name: "Brasil") { |t| t.short_name = "BRA"; t.country_code = "bra" }

marrocos = Team.find_by("name ILIKE ?", "%morocco%") ||
           Team.find_by("name ILIKE ?", "%marrocos%") ||
           Team.find_or_create_by!(name: "Marrocos") { |t| t.short_name = "MAR"; t.country_code = "mar" }

demo_match = Match.find_or_create_by!(
  home_team: brasil,
  away_team: marrocos,
  tournament_id: nil
) do |m|
  m.scheduled_at = 1.week.from_now.beginning_of_day + 20.hours
  m.status = :scheduled
  m.venue = "Demo Stadium"
end

single_pool = Pool.find_or_initialize_by(name: "Brasil × Marrocos - Demo")
single_pool.assign_attributes(
  pool_scope: :single_match,
  match: demo_match,
  admin: admin_user,
  status: :open,
  visibility: :public_pool,
  description: "Bolão de jogo único demo",
  lock_before_minutes: 5,
  scoring_config: Pool::SCORING_DEFAULTS
)
single_pool.save!
puts "Single match pool: #{single_pool.name} (#{single_pool.invite_code})"
