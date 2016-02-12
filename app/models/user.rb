class User < ActiveRecord::Base
  has_many :accounts, dependent: :destroy

  IMAGES = {
    scapegoat: "/assets/scapegoat.png",
    news: "/assets/news.png",
    activity_logger: "/assets/activity_logger.png",
  }.freeze

  def self.scapegoat
    find_or_create_by(name: "生け贄", image: IMAGES[:scapegoat])
  end

  def self.news
    find_or_create_by(name: "村のラジオ", image: IMAGES[:news])
  end

  def self.activity_logger
    find_or_create_by(name: "システムメッセージ", image: IMAGES[:activity_logger])
  end

  def scapegoat?
    image == IMAGES[:scapegoat]
  end

  def news?
    image == IMAGES[:news]
  end

  def activity_logger?
    image == IMAGES[:activity_logger]
  end
end
