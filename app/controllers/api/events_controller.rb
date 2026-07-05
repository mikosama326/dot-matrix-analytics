class Api::EventsController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :verify_telemetry_api_key, only: [:create]

  def create
    if params[:event_name] == "heartbeat"
      return handle_heartbeat
    end

    if ["item_placed", "item_deleted"].include?(params[:event_name])
      session = touch_session_update_items(params[:player_id], params[:session_id])
      unless session.save
        return render json: { status: "error", errors: session.errors.full_messages },
        status: :unprocessable_entity
      end
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

  def verify_telemetry_api_key
    expected_key = ENV["TELEMETRY_API_KEY"]

    return if expected_key.present? &&
              ActiveSupport::SecurityUtils.secure_compare(
                request.headers["X-Dot-Matrix-Api-Key"].to_s,
                expected_key
              )

    render json: { status: "error", error: "unauthorized" }, status: :unauthorized
  end

  def handle_heartbeat
    session = touch_session_current_state(params[:player_id], params[:session_id])
    session.active_seconds = params.dig(:properties, :open_seconds).to_i

    if session.save
      broadcast_dashboard_update
      render json: { status: "ok", handled_as: "session_update" }, status: :created
    else
      render json: { status: "error", errors: session.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def touch_session_current_state(player_id, session_id)
    session = GameSession.find_or_initialize_by(session_id: session_id)
    properties = params[:properties] || {}

    session.player_id = player_id
    session.last_seen_at = Time.current
    session.active_seconds = properties[:open_seconds].to_i if properties.key?(:open_seconds)
    session.last_dots_available = properties[:dot_count].to_i if properties.key?(:dot_count)
    session.last_dot_production_rate = properties[:dot_production_rate].to_f if properties.key?(:dot_production_rate)
    session.last_dot_consumption_rate = properties[:dot_consumption_rate].to_f if properties.key?(:dot_consumption_rate)
    session.last_event_name = params[:event_name]

    session
  end

  def touch_session_update_items(player_id, session_id)
    session = GameSession.find_or_initialize_by(session_id: session_id)
    properties = params[:properties] || {}
    session.player_id = player_id
    session.session_id = session_id

    session.last_seen_at = Time.current
    
    session.last_dots_available = properties[:dots_after].to_i if properties.key?(:dots_after)
    session.last_item_id = properties[:item_id] if properties.key?(:item_id)
    session.last_item_level = properties[:item_level].to_i if properties.key?(:item_level)
    session.last_event_name = params[:event_name]

    session
  end

  def broadcast_dashboard_update
    ActionCable.server.broadcast("dashboard", {
      total_events: AnalyticsEvent.count,
      total_sessions: GameSession.count,
      unique_players: GameSession.distinct.count(:player_id),
      total_active_seconds: GameSession.sum(:active_seconds),
      event_counts: AnalyticsEvent.group(:event_name).count,
      recent_events: AnalyticsEvent.order(created_at: :desc).limit(10).map do |event|
      {
        created_at: event.created_at.iso8601,
        event_name: event.event_name,
        properties: event.properties || {}
      }
    end,

    recent_sessions: GameSession.order(last_seen_at: :desc).limit(10).map do |session|
      {
        last_seen_at: session.last_seen_at&.iso8601,
        active_seconds: session.active_seconds.to_i,
        last_dots_available: session.last_dots_available.to_i,
        last_dot_production_rate: session.last_dot_production_rate.to_f,
        last_dot_consumption_rate: session.last_dot_consumption_rate.to_f,
        last_item_id: session.last_item_id,
        last_item_level: session.last_item_level,
        last_event_name: session.last_event_name
      }
    end
    })
  end

end
