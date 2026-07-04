class GameSession < ApplicationRecord
  validates :player_id, presence: true
  validates :session_id, presence: true, uniqueness: true
  validates :active_seconds,
            numericality: { greater_than_or_equal_to: 0 },
            allow_nil: true
end
