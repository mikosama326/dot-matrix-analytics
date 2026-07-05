class AddSnapshotFieldsToGameSessions < ActiveRecord::Migration[8.1]
  def change
    add_column :game_sessions, :last_event_name, :string
    add_column :game_sessions, :last_item_id, :string
    add_column :game_sessions, :last_item_level, :integer
    add_column :game_sessions, :last_dots_available, :integer
  end
end
