class AddThesportsdbToApiProviderType < ActiveRecord::Migration[8.1]
  def up
    # Add external_id columns for deduplication
    add_column :teams,   :external_provider_id,  :string unless column_exists?(:teams, :external_provider_id)
    add_column :teams,   :external_provider_name, :string unless column_exists?(:teams, :external_provider_name)
    add_column :matches, :external_provider_name, :string unless column_exists?(:matches, :external_provider_name)

    add_index :teams,   [:external_provider_id, :external_provider_name],
                        unique: true, name: "idx_teams_on_provider", where: "external_provider_id IS NOT NULL"
    add_index :matches, [:external_id, :external_provider_name],
                        unique: true, name: "idx_matches_on_provider", where: "external_id IS NOT NULL"
  end

  def down
    remove_column :teams,   :external_provider_id,   if_exists: true
    remove_column :teams,   :external_provider_name, if_exists: true
    remove_column :matches, :external_provider_name, if_exists: true
  end
end
