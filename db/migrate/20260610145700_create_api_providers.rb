class CreateApiProviders < ActiveRecord::Migration[8.1]
  def change
    create_table :api_providers do |t|
      t.string :name, null: false
      t.integer :provider_type, null: false, default: 0
      t.string :base_url
      t.boolean :active, null: false, default: true
      t.jsonb :config, default: {}

      t.timestamps
    end
  end
end
