class Epilogue < Scene
  def next_scene
    Fin.new(room: room, prev_scene_id: self.id)
  end

  def label
    "エピローグ"
  end

  def information(citizen = nil)
    "after"
  end
end
