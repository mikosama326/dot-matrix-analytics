class RenameLastSeenToLastSeenAt < ActiveRecord::Migration[8.1]
  def change
    rename_column :game_sessions, :last_seen, :last_seen_at
  end
end
