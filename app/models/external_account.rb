class ExternalAccount < ActiveRecord::Base
  belongs_to :user

  def self.register(auth)
    info = auth[:info]
    account = find_or_initialize_by(
      provider: auth[:provider],
      uid: auth[:uid],
    )
    account[:nickname] = info[:nickname]
    account[:image] = info[:image]

    unless account[:user_id]
      user = User.create!(name: account.nickname, image: account[:image])
      account[:user_id] = user.id
    end
    account.save!

    account
  end
end
