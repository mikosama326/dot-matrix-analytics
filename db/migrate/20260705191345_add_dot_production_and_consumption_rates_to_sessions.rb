class AddDotProductionAndConsumptionRatesToSessions < ActiveRecord::Migration[8.1]
  def change
    add_column :game_sessions, :last_dot_production_rate, :integer
    add_column :game_sessions, :last_dot_consumption_rate, :integer
  end
end
