class AnalyticsEvent < ApplicationRecord
    VALID_EVENT_NAMES = [
        "game_started",
        "game_ended",
        "item_placed",
        "item_deleted"
    ]

    validates :player_id, presence: true
    validates :session_id, presence: true
    validates :event_name, presence: true, inclusion: { in: VALID_EVENT_NAMES }
end
