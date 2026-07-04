class Api::EventsController < ApplicationController
  skip_before_action :verify_authenticity_token

  def create
    if params[:event_name] == "heartbeat"
      return handle_heartbeat
    end

    session = touch_session(params[:player_id], params[:session_id])
    unless session.save
      return render json: { status: "error", errors: session.errors.full_messages },
      status: :unprocessable_entity
    end

    event = AnalyticsEvent.new(
      player_id: params[:player_id],
      session_id: params[:session_id],
      event_name: params[:event_name],
      properties: params[:properties] || {}
    )

    if event.save
      broadcast_dashboard_update
      render json: { status: "ok", id: event.id, handled_as: "event" }, status: :created
    else
      render json: { status: "error", errors: event.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def index
    events = AnalyticsEvent.order(created_at: :desc).limit(50)
    render json: events
  end

  #----------------------------------------------------------
  private

  def handle_heartbeat
    session = touch_session(params[:player_id], params[:session_id])
    session.active_seconds = params.dig(:properties, :open_seconds).to_i

    if session.save
      broadcast_dashboard_update
      render json: { status: "ok", handled_as: "session_update" }, status: :created
    else
      render json: { status: "error", errors: session.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def touch_session(player_id, session_id)
    session = GameSession.find_or_initialize_by(session_id: session_id)

    session.player_id = player_id
    session.last_seen_at = Time.current
    session.active_seconds ||= 0

    session
  end

  def broadcast_dashboard_update
    ActionCable.server.broadcast("dashboard", {
      total_events: AnalyticsEvent.count,
      total_sessions: GameSession.count,
      unique_players: GameSession.distinct.count(:player_id),
      total_active_seconds: GameSession.sum(:active_seconds),
      event_counts: AnalyticsEvent.group(:event_name).count,
      recent_events: AnalyticsEvent.order(created_at: :desc).limit(10).map(&:attributes),
      recent_sessions: GameSession.order(last_seen_at: :desc).limit(10).map(&:attributes)
    })
  end

end
