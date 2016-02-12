class Night < Scene
  def next_scene
    Evening.new(room: room, prev_scene_id: self.id)
  end

  def executed
    v = wolve_votes.order(id: :asc).first
    if guard_vote && guard_vote.to == v.to
      nil
    else
      v.to
    end
  end

  def next_messages
    [
      (executed ? 
        "#{executed.name} が無残な姿で発見されました。"
        : "平和な夜でした。"
      )
    ]
  end

  def label
    "第#{nth}の夜"
  end

  def information(citizen = nil)
    message = "夜です。"
    return message unless citizen

    message << "あなたは「#{citizen.role.name}」です。"
    special = citizen.special_message
    message << special if special

    message
  end
end
