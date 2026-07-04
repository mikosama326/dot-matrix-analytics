class DashboardController < ApplicationController
  def index
    assign_dashboard_data
  end
#-----------------------------------------------
  private
  def assign_dashboard_data
    @total_events = AnalyticsEvent.count
    @total_sessions = GameSession.count
    @unique_players = GameSession.distinct.count(:player_id)
    @total_active_seconds = GameSession.sum(:active_seconds)

    @recent_events = AnalyticsEvent.order(created_at: :desc).limit(20)
    @recent_sessions = GameSession.order(last_seen_at: :desc).limit(20)

    @event_counts = AnalyticsEvent.group(:event_name).count
    @item_placed_counts = AnalyticsEvent
  .where(event_name: "item_placed")
  .group("json_extract(properties, '$.item_id')")
  .order(Arel.sql("COUNT(*) DESC"))
  .count
  end
end
