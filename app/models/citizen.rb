class Citizen < ActiveRecord::Base
  belongs_to :user
  belongs_to :room
  # belongs_to :role

  delegate :scapegoat?, :name, to: :user
  delegate :side, :wolf?, :lovers?, :guard?, to: :role
  delegate :current_scene, to: :room

  scope :alived, -> { where(alive: true) }
  scope :wolves, -> { where(role_id: Role[:wolf].id) }

  def role
    Role.find(role_id)
  end

  def action_required?
    return false if scapegoat?
    role.action_required?(current_scene)
  end

  def dead?
    not alive?
  end

  def god_view?
    dead? || role.visitor?
  end

  def current_vote
    current_scene.votes.living.find_by(from: self)
  end

  def vote_to(target)
    unless already_voted_on_current_scene?
      current_scene.votes.create!(from: self, to: target)
      if wolf?
        room.citizens.alived.wolves.each do |c|
          next if c.id == self.id
          current_scene.votes.create!(from: c, to: target)
        end
      end
      room.log_activity "#{self.user.name} が #{target.user.name} に投票しました"
    end

    if current_scene.voted_all?
      if current_scene.avoid_votes?
        current_scene.avoid_votes
        return
      end

      at = current_scene.frozen_at - Time.now
      if current_scene.evening? || at < 0
        SceneChange.new.perform(room.id, room.current_scene.id)
      else
        SceneChange.perform_in(at, room.id, room.current_scene.id)
      end
    end
  end

  def already_voted_on_current_scene?
    !! current_vote
  end

  def kill
    update_attribute(:alive, false)
    reload
  end

  def last_vote
    current_scene.prev.votes.living.find_by(from: self)
  end

  def win?
    return unless room.winner_fixed?
    room.winner_side == side
  end

  def lovers
    lovers_id = Role[:lovers].id
    self.class.where(room_id: room.id, role_id: lovers_id)
  end

  def special_message
    if current_scene.evening?
      case role
      when Lovers
        others = lovers.where.not(id: self.id)
        "他の共有者は #{others.map{|c| c.user.name}.join(", ")} です。"
      when Uranai
        "#{last_vote.to.user.name} は人狼#{last_vote.to.role.wolf? ? "でした" : "ではありませんでした" }"
      when Reinou
        "夜になると、今日の投票で処刑された人が「人狼」か「人狼じゃない」かがわかります。"
      when Fullmooner
        "村人と同じく特殊な能力はありませんが、人狼陣営に属しています。"
      end
    else
      case role
      when Lovers
        others = lovers.where.not(id: self.id)
        "他の共有者は #{others.map{|c| c.user.name}.join(", ")} です。夜の間に共有者同士で話し合えます。"
      when Guard
        "守護したい相手を選んでください。守護した人が人狼に襲われた場合、その人は死なずに夜を越せます。（※最初の夜は何もできません）"
      when Wolf
        "ターゲットを選んでください。人狼が複数居る場合は、最初に投票されたターゲットを襲います。"
      when Uranai
        "昼になると、夜のあいだに選んだ相手が「人狼」か「人狼じゃない」かがわかります。"
      when Fullmooner
        "村人と同じく特殊な能力はありませんが、人狼陣営に属しています。"
      when Reinou
        if current_scene.prev.prologue?
          "夜になると、昼に投票で処刑された人が「人狼」か「人狼じゃない」かがわかります。（※最初の夜は何もわかりません）"
        else
          last_killed = current_scene.prev.executed
          if last_killed
            "#{last_killed.name} は 人狼#{last_killed.role.wolf? ? "でした" : "ではありませんでした"}"
          end
        end
      end
    end
  end
end
