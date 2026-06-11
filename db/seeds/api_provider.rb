puts "Seeding API providers..."

# TheSportsDB — the only provider. All tournament imports go through the admin UI.
provider = ApiProvider.find_or_initialize_by(name: "TheSportsDB")
provider.assign_attributes(
  provider_type: :thesportsdb,
  base_url:      "https://www.thesportsdb.com/api/v1/json",
  active:        true,
  config:        { "api_key" => "123" }
)
provider.save!
puts "ApiProvider: #{provider.name} (key: #{provider.config['api_key']})"
