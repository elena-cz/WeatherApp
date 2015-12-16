class CreateForecasts < ActiveRecord::Migration
  def change
    create_table :forecasts do |t|
      t.string :city_name
      t.string :state_code
      t.integer :user_id

      t.timestamps null: false
    end
  end
end
