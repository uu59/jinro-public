class Vote < ActiveRecord::Base
  belongs_to :scene
  belongs_to :from, foreign_key: "from_citizen_id", class_name: "Citizen"
  belongs_to :to, foreign_key: "to_citizen_id", class_name: "Citizen"

  scope :living, -> { where(avoided: false) }

  validate :validate_first_night
  validate :validate_wolf_votes_wolf
  validate :validate_alived_citizen
  validate :validate_self

  def validate_first_night
    return true unless scene.first_night?

    if from.wolf? && !to.scapegoat?
      errors.add(:base, "初夜は#{User.scapegoat.name}以外を殺せません")
    end
  end

  def validate_wolf_votes_wolf
    if scene.night? && from.wolf? && to.wolf?
      errors.add(:base, "人狼は人狼を殺せません")
    end
  end

  def validate_alived_citizen
    if to.dead?
      errors.add(:base, "死人に投票はできません")
    end
  end

  def validate_self
    if scene.night? && from == to
      errors.add(:base, "自分を対象にはできません")
    end
  end
end
