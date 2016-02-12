class Prologue < Scene
  def next!
    with_lock do
      if room.winner_fixed?
        room
      else
        next_scene.save!
        update_attribute(:finished, true)
        room.scene_change!
      end
    end
  end

  def label
    "プロローグ"
  end

  def next_scene
    Night.new(room: room, prev_scene_id: self.id)
  end

  def information(citizen = nil)
    "before"
  end
end
