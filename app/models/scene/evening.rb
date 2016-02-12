class Evening < Scene
  def next_scene
    Night.new(room: room, prev_scene_id: self.id)
  end

  def executed
    if avoid_votes?
      nil
    else
      most_voted_citizens.first
    end
  end

  def next_messages
    [
      vote_result_messsage,
      "#{executed.name} が投票で処刑されました。"
    ]
  end


  def label
    "第#{nth}の昼"
  end

  def information(citizen = nil)
    message = "昼です。"
    return message unless citizen

    message << "あなたは「#{citizen.role.name}」です。"
    special = citizen.special_message
    message << special if special

    message
  end
end
