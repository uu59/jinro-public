class SceneChange
  # include SuckerPunch::Job
  include Sidekiq::Worker

  def perform(room_id, scene_id)
    ActiveRecord::Base.connection_pool.with_connection do
      scene = Room.find(room_id).current_scene
      scene.with_lock do
        return if scene.id != scene_id
        return if scene.finished?
        return unless scene.voted_all?

        scene.execute! if scene.evening? || scene.night?
      end
    end
  end
end
