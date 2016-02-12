class Channel
  attr_reader :fragment, :secret_token

  def initialize(fragment, secret_token = nil)
    @fragment = fragment
    @secret_token = secret_token
  end

  def self.global_send(message = {})
    json = MultiJson.dump(message.merge(time: Time.now.to_f))
    App.redis.publish("global", json)
  end

  def self.room_send(room, message = {})
    json = MultiJson.dump(message.merge(time: Time.now.to_f))
    App.redis.publish(room.room_channel_id, json)
  end

  def id
    Digest::SHA1.hexdigest("#{secret_token}/#{fragment}")
  end

  def god_id
    Digest::SHA1.hexdigest("#{secret_token}/god")
  end

  def god_channel?
    id == god_id
  end

  def send(message)
    last_id = App.redis.llen(id)
    App.redis.multi do
      now = Time.now
      message[:time] = now.strftime("%H:%M:%S")
      message[:anchor] = anchor
      message[:id] = last_id + 1
      json = MultiJson.dump(message)
      App.redis.rpush(id, json)
      App.redis.publish(id, json)
    end
    message
  end

  def anchor
    "log" << Time.now.to_f.to_s.gsub(".", "")
  end

  def write(message)
    last_id = App.redis.llen(id)
    last_god_id = App.redis.llen(god_id)

    App.redis.multi do
      now = Time.now
      message[:time] = now.strftime("%H:%M:%S")
      message[:anchor] = anchor
      message[:id] = last_id + 1
      json = MultiJson.dump(message)
      App.redis.rpush(id, json)
      App.redis.publish(id, json)

      unless god_channel?
        json = MultiJson.dump(message.merge(id: last_god_id + 1))
        App.redis.rpush(god_id, json)
        App.redis.publish(god_id, json)
      end
    end
    message
  end

  private

  def full_path_of(name)
    room.log_root + hex(room.secret_token + name.to_s)
  end

  def hex(str)
    Digest::SHA1.hexdigest(str)
  end
end
