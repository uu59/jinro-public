class Room < ActiveRecord::Base
  has_many :citizens, dependent: :destroy
  has_many :scenes, dependent: :destroy
  belongs_to :created_by, foreign_key: :created_by, class_name: "User"

  before_create do
    self.secret_token = SecureRandom.base64(32)
    self.name = self.name.presence || DEFAULT_NAMES.sample
  end

  after_create do
    Prologue.create(room: self)
    join(User.scapegoat)
    join(created_by)
    Room.update_valid_channel_ids
    broadcast_news "#{name}村が作成されました。"
  end

  DEFAULT_NAMES = %w(
    チェダー エダム ゴーダ カマンベール グリュイエール
    ロックフォール ゴルゴンゾーラ リヴァロ エメンタール
    ブルゴーニュ
  )
  ARCHIVE_AFTER_FINISH = 3.minutes
  DEFAULT_OPTIONS = ActiveSupport::HashWithIndifferentAccess.new({
    first_night_time: 30.seconds,
    night_time: 2.minutes,
    evening_time: 5.minutes,
    even_game_for_avoid_votes_count: 4,
  }).freeze
  VALID_STREAM_IDS_KEY = "active_pub_channels"

  scope :prologue, -> { where(state: "prologue") }
  scope :playing, -> { where(state: "playing") }
  scope :epilogue, -> { where(state: "epilogue") }
  scope :archived, -> { where(state: "fin") }
  scope :not_archived, -> { where.not(state: "fin") }

  def options
    DEFAULT_OPTIONS.merge(attributes["options"])
  end

  def ready?
    citizens.size == 4
  end

  def to_json_hash
    keys = %i(id name created_at)
    data = keys.each_with_object({}) do |k, result|
      result[k] = attributes[k.to_s]
    end
    citizens = Citizen.where(room: self).eager_load(:user)
    data.merge({
      state: state,
      archived: archived?,
      scene: current_scene.attributes.merge(type: current_scene.type.downcase),
      frozenChat: current_scene.frozen_chat?,
      frozenAt: current_scene.frozen_at,
      isReady: ready?,
      roles: roles,
      rolePattern: role_pattern_key,
      citizens: citizens.map do |c|
        data = {
          user:  c.user,
          alive: c.alive,
        }
        if finished?
          data.merge!({
            role: c.role.name,
          })
        end
        data
      end
    })
  end

  def to_json
    MultiJson.dump(as_json)
  end

  def roles
    return {} unless role_pattern_key
    roles = RolePattern.patterns[role_pattern_key].map(&:name)
    roles.inject({}) do |res, role|
      res[role] = roles.count(role)
      res
    end
  end

  def start!(role_pattern: nil)
    with_lock do
      role_pattern ||= RolePattern.patterns_for_count(count: citizens.count).keys.sample
      roles = RolePattern.patterns[role_pattern]
      if role_pattern == "TEST"
        roles = RolePattern.patterns_for_test
      end
      return if roles.empty?

      self.role_pattern_key = role_pattern

      # 生け贄は人狼にならない
      scapegoat_role = (roles.reject{|r| r.id == Role[:wolf].id}).sample
      citizens.find_by(user: User.scapegoat).update_attribute(:role_id, scapegoat_role.id)
      roles.delete_at(roles.index(scapegoat_role))

      roles.shuffle
      citizens.each do |citizen|
        next if citizen.scapegoat?
        citizen.update(role_id: roles.shift.id)
      end
      citizens.reload

      current_scene.next!
      update_attribute(:state, "playing")
    end
  end

  def finish!
    Epilogue.create(room: self, prev_scene_id: current_scene.id)
    update_attribute(:state, "epilogue")
    broadcast_news "#{ARCHIVE_AFTER_FINISH.to_i} 秒後にアーカイブされます。"
    FinJob.perform_in(ARCHIVE_AFTER_FINISH, id)
    reload
  end

  def send_finish_message
    citizens = Citizen.where(room: self).order(id: :desc).eager_load(:user).map do |c|
      "#{c.user.name}(#{c.role.name})"
    end

    broadcast_news citizens.join("\n")
  end

  def before_start?
    current_scene.prologue?
  end

  def started?
    !before_start? && !finished?
  end

  def playing?
    state == "playing"
    # started? && not(finished?)
  end

  def finished?
    reload.current_scene.epilogue? || archived?
  end

  def archived?
    reload.current_scene.fin?
  end

  def winner_side
    alived = citizens.alived
    wolf = alived.find_all{|c| c.side == :wolf }.length

    return "村人" if wolf.zero?

    all = alived.length
    others = all - wolf
    if others <= wolf
      "人狼"
    end
  end

  def messages
    # for SSR
    return [] unless finished?
    ch = Channel.new("god", secret_token)
    App.redis.lrange(ch.id, 0, -1).map {|m| MultiJson.load(m) }
  end

  def winner_fixed?
    winner_side
  end

  def evening?
    return unless playing?
    current_scene.evening?
  end

  def night?
    return unless playing?
    current_scene.night?
  end

  def current_scene
    scenes.where(finished: false).order(id: :desc).first
  end

  def join(user)
    citizens.create(user: user, role_id: Role[:visitor].id)
  end

  def leave(user)
    citizens.find_by(user: user).destroy
  end

  def members(with_role: false)
    citizens.order(id: :asc).eager_load(:user).map do |c|
      data = c.attributes.merge(user: c.user)
      data.delete("role_id")
      if finished? || with_role
        data.merge!(role: c.role.name)
      end
      data
    end
  end

  def room_channel_id
    "room-#{id}"
  end

  def scene_change!
    current_scene.reload
    send_room_event(event: "scene:changed", scene: current_scene, roomId: id)

    if current_scene.frozen_at
      at = current_scene.frozen_at - Time.now
      ScheduledEventJob.perform_in(at, id, current_scene.id, {
        event: "room:updated"
      })
    end
  end

  def current_information_for(user = nil)
    return "プレイ前です。人数が揃うとゲーム開始できます。" if before_start?

    if finished?
      return "ゲームが終了しました。#{winner_side} の勝利です。"
    end
    current_scene.information(user)
  end

  def send_room_event(message)
    Channel.room_send(self, message)
  end

  def broadcast_news(body)
    trans = Transmitter.new(room: self, user: User.news)
    trans << body
  end

  def log_activity(body)
    trans = Transmitter.new(room: self, user: User.activity_logger)
    trans << body
  end

  def clear_chat_log
    trans = Transmitter.new(room: self, user: nil)
    trans.all_channel_ids.each do |id|
      App.redis.del(id)
    end
  end

  def self.update_valid_channel_ids
    ids = ["global"]
    not_archived.each do |room|
      trans = Transmitter.new(room: room, user: nil)
      ids.concat(trans.all_channel_ids)
      ids.concat [room.room_channel_id]
    end
    App.redis.set(VALID_STREAM_IDS_KEY, ids)
  end
end
