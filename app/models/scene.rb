class Scene < ActiveRecord::Base
  belongs_to :room
  has_many :votes

  after_create do
    Room.update_valid_channel_ids

    next if prologue?
    next if fin?

    room.broadcast_news "-- #{room.current_scene.label} --"
  end

  def prev
    room.scenes.find_by(id: prev_scene_id)
  end

  def next
    # TODO?
  end

  def next!
    with_lock do
      if room.winner_fixed?
        room.finish!
      else
        next_scene.save!
      end

      update_attribute(:finished, true)
      room.reload
    end
  end

  def execute!
    executed.kill if executed
    messages = next_messages

    next!
    room.scene_change!

    # scene_changeのあと
    room.reload
    messages.each do |message|
      room.broadcast_news message
    end

    if room.finished?
      room.send_finish_message
    end
  end

  def first_night?
    night? && prev.prologue?
  end

  def nth
    room.scenes.where(type: type).count
  end

  def wolves
    room.citizens.alived.find_all{|c| c.wolf?}
  end

  def wolve_votes
    votes.living.where(from_citizen_id: wolves.map(&:id))
  end

  def guard_vote
    guard_citizen_id = room.citizens.alived.find{|c| c.guard?}
    votes.living.find_by(from_citizen_id: guard_citizen_id)
  end

  def avoid_votes
    # update_allの前
    room.broadcast_news vote_result_messsage

    transaction do
      update_attribute(:vote_avoided_count, vote_avoided_count + 1)
      votes.living.update_all(avoided: true)
      reload
    end

    room.broadcast_news "同票になりました。再投票してください。（#{vote_avoided_count}回目）"
    room.send_room_event({
      event: "vote:invalidated"
    })
  end

  def vote_result_messsage
    message = "投票結果：\n"
    message << votes.living.map do |v|
      "#{v.from.name} → #{v.to.name}\n"
    end.join
    message
  end

  def voted_all?
    voters = room.citizens.alived.find_all{|c| c.action_required? }
    voters.length == votes.living.count
  end

  def voted_enough?
    case self
    when evening?
      voters = room.citizens.alived.find_all{|c| c.action_required? }
      voters.length == votes.living.count
    when night?
      # TODO
    end
  end

  def unvoted
    voters = room.citizens.alived.find_all{|c| c.action_required? }
    voters - votes.living.map(&:from)
  end

  def most_voted_citizens
    targets = votes.living.map{|v| v.to.id}
    stats = targets.group_by{|t| targets.count(t) }
    max_vote = stats.keys.sort.last
    room.citizens.where(id: stats[max_vote].uniq)
  end

  def avoid_votes?
    return false unless evening?
    most_voted_citizens.length > 1
  end

  def frozen_chat?
    frozen_at && frozen_at < Time.now
  end

  def frozen_at
    return nil if prologue? || epilogue?

    time =
      if night?
        first_night? ? room.options[:first_night_time] : room.options[:night_time]
      else
        room.options[:evening_time]
      end
    self.created_at + time
  end

  def night?
    is_a?(Night)
  end

  def evening?
    is_a?(Evening)
  end

  def prologue?
    is_a?(Prologue)
  end

  def epilogue?
    is_a?(Epilogue)
  end

  def fin?
    is_a?(Fin)
  end
end
