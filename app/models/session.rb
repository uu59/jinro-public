class Session < ActiveRecord::Base
  scope :active, -> {
    where("created_at > ?", Time.now - 86400)
  }
  scope :inactive, -> {
    where("created_at <= ?", Time.now - 86400)
  }

  before_create do
    transaction do
      self.unique_id = generate_unique_id
    end
    self.body_json = MultiJson.dump(body)
  end

  def self.restore(unique_id)
    active.find_by(unique_id: unique_id)
  end

  def body=(body)
    @body = body
  end

  def body
    @body ||=
      begin
        raw = MultiJson.load(body_json)
        case raw
        when Hash
          raw.with_indifferent_access
        else
          raw
        end
      end
  end

  def generate_unique_id
    loop do
      id = SecureRandom.hex(48)
      break id unless self.class.exists?(unique_id: id)
    end
  end

end
