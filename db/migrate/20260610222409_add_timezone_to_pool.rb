class AddTimezoneToPool < ActiveRecord::Migration[8.1]
  def change
    add_column :pools, :timezone, :string
  end
end
