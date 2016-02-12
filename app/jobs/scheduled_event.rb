class ScheduledEventJob
  # include SuckerPunch::Job
  include Sidekiq::Worker

  def perform(room_id, scene_id, payload)
    ActiveRecord::Base.connection_pool.with_connection do
      room = Room.find(room_id)
      room.with_lock do
        return if room.current_scene.id != scene_id
        room.send_room_event(payload)
      end
    end
  end
end
