class Rule
  attr_reader :room

  def initialize(room)
    @room = room
  end

  def even_game_for_avoid_votes_count
    room.options[:even_game_for_avoid_votes_count]
  end
end
