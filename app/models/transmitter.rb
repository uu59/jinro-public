class Transmitter
  attr_reader :room, :user

  def initialize(room: , user: )
    @room = room
    @user = user
  end

  def channel_token
    # for API
    channel.id
  end

  def <<(body)
    message = payload(body)

    channels.each do |ch|
      if ch.god_channel?
        ch.send(message)
      else
        ch.send(message.merge(role: {}))
      end
    end
  end

  def payload(body)
    {
      from: user,
      body: body,
      scene: room.current_scene.type.downcase,
      sender_type: sender_type,
      role: {
        name: citizen.try(:role).try(:name),
        short_name: citizen.try(:role).try(:short_name),
        side: citizen.try(:side),
      }
    }
  end

  def all_channel_ids
    sender_types = %i(news activity_logger visitor ghost lovers wolf citizen)
    all_channel_names = room.scenes.map do |scene|
      sender_types.map do |st|
        room.citizens.map do |c|
          channel_names(scene: scene, sender: st, citizen: c)
        end
      end
    end.flatten.uniq.compact

    all_channel_names.map{|c| Channel.new(c, room.secret_token) }.map(&:id)
  end

  private

  def sender_type
    return :news if user && user.news?
    return :activity_logger if user && user.activity_logger?
    return :visitor if visitor?
    return :ghost if dead?
    return :lovers if citizen.lovers?
    return :wolf if citizen.wolf?
    :citizen
  end

  def citizen_channels
    room.citizens.map{|c| "#{room.current_scene.id}/#{c.id}" }
  end

  def citizen
    room.citizens.find_by(user: user)
  end

  def visitor?
    not citizen?
  end
  
  def citizen?
    citizen
  end

  def dead?
    citizen && citizen.dead?
  end

  def channels
    if user.news?
      return Array(channel_names).map {|n| Channel.new(n, room.secret_token) }
    end

    [
      channel,
      Channel.new("god", room.secret_token),
    ].uniq(&:id)
  end

  def channel
    Channel.new(Array(channel_names).first, room.secret_token)
  end

  def channel_names(scene: nil, sender: nil, citizen: nil)
    # for API
    scene ||= room.current_scene
    sender ||= sender_type
    citizen ||= send(:citizen)
    case scene
    when Prologue
      ["prologue", "god"]

    when Epilogue
      ["god"]

    when Evening
      case sender
      when :wolf, :citizen, :lovers
        [scene.id.to_s]
      when :ghost, :visitor, :activity_logger
        ["god"]
      when :news
        %W(god #{scene.id})
      end

    when Night
      case sender
      when :wolf
        ["#{scene.id}/wolf"]
      when :lovers
        ["#{scene.id}/lovers"]
      when :citizen
        ["#{scene.id}/#{citizen.id}"]
      when :ghost, :visitor, :activity_logger
        ["god"]
      when :news
        scene_id = scene.id
        %W(god #{scene_id}/wolf) + room.citizens.map do |c|
          "#{scene_id}/#{c.id}"
        end
      end
    end
  end

end
