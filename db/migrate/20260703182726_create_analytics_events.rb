class CreateAnalyticsEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :analytics_events do |t|
      t.string :player_id
      t.string :session_id
      t.string :event_name
      t.json :properties

      t.timestamps
    end
  end
end
