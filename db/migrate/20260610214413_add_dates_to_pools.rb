class AddDatesToPools < ActiveRecord::Migration[8.1]
  def change
    add_column :pools, :starts_at, :datetime
    add_column :pools, :ends_at, :datetime
  end
end
