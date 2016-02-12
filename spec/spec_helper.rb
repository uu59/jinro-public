ENV["RACK_ENV"] = "test"
require_relative "../config/boot.rb"

require "benchmark"


require "rack/test"
Dir["./spec/support/**/*.rb"].each{|file| require file }

if ENV["COVERAGE"]
  require "simplecov"
  SimpleCov.start
end

# ActiveRecord::Base.logger = Logger.new(STDOUT)

require 'sidekiq/testing'
Sidekiq::Testing.inline!

RSpec.configure do |config|
  config.before(:suite) do
    # DatabaseCleaner.strategy = :truncation, {:except => %w[roles]}
  end

  config.around(:each) do |example|
    ActiveRecord::Base.transaction do
      example.run
      raise ActiveRecord::Rollback
    end
  end

  config.after(:each) do
    # ActiveRecord::Base.connection.tables.each do |table|
    #   next if table == "roles"
    #   ActiveRecord::Base.connection.execute("TRUNCATE #{table}")
    # end
  end

  config.include CreateRoom

  config.define_derived_metadata do |meta|
    meta[:aggregate_failures] = true unless meta.key?(:aggregate_failures)
  end
end
