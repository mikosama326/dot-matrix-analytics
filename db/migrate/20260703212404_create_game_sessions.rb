class CreateGameSessions < ActiveRecord::Migration[8.1]
  def change
    create_table :game_sessions do |t|
      t.string :player_id
      t.string :session_id
      t.integer :active_seconds
      t.datetime :last_seen

      t.timestamps
    end
  end
end
