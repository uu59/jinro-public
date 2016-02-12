ENV["RACK_ENV"] ||= "development"
require "yaml"
require "bundler"
Bundler.require(:default, ENV["RACK_ENV"])
Dotenv.load

module App
  def self.root
    Pathname.new(__FILE__) / "../../"
  end

  def self.session_id
    "jinro_session_id"
  end

  def self.env
    ENV["RACK_ENV"].to_sym
  end

  def self.database_yml
    #App.root.join("config/database.#{ENV["RACK_ENV"]}.yml")
    App.root.join("config/database.yml")
  end

  def self.database
    YAML.load(IO.read database_yml)[env.to_s]
  end

  def self.redis
    @redis ||= Redis.new(host: ENV["REDIS_HOST"], port: ENV["REDIS_PORT"])
  end

  def self.github_tokens
    {
      token:  ENV["GITHUB_TOKEN"],
      secret: ENV["GITHUB_SECRET"],
    }
  end
end

Sidekiq.configure_client do |config|
  config.redis = { url: "redis://#{ENV["REDIS_HOST"]}:#{ENV["REDIS_PORT"]}", namespace: "sidekiq_#{App.env}" }
end

Sidekiq.configure_server do |config|
  config.average_scheduled_poll_interval = 1
  config.redis = { url: "redis://#{ENV["REDIS_HOST"]}:#{ENV["REDIS_PORT"]}", namespace: "sidekiq_#{App.env}" }
end

ActiveRecord::Base.logger = Logger.new(STDOUT) if App.env == :development
ActiveRecord::Base.establish_connection(App.database)

Dir["./app/**/*.rb"].sort_by{|f| f.scan("/").length}.each do |f|
  require f
end


Arproxy.configure do |config|
  config.adapter = ActiveRecord::ConnectionAdapters::PostgreSQLAdapter
  config.use SlowQueryLogger, 1000
end
Arproxy.enable!

