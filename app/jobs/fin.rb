class FinJob
  # include SuckerPunch::Job
  include Sidekiq::Worker

  def perform(room_id)
    ActiveRecord::Base.connection_pool.with_connection do
      room = Room.find(room_id)
      return if room.archived?
      return unless room.finished?

      env = ENV.to_h.merge({
        "ROOM_ID" => room.id.to_s
      })
      if App.env != :test
        unless system(env, "bundle exec rake create:archive")
          raise "SSR failed"
        end
      end

      room.with_lock do
        room.current_scene.next_scene.save!
        room.update_attribute(:state, "fin")
      end

      room.send_room_event({
        event: "room:updated"
      })
    end
  end
end
