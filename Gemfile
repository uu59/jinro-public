source "https://rubygems.org"

gem "grape", "~> 0.14.0"
gem "bcrypt", "~> 3.1.10"
gem "redis", "~> 3.2"
gem "hiredis", "~> 0.6.1"
# gem "oj"
gem "ridgepole", "~> 0.6.3"
gem "pg"
gem "activerecord", "~> 4.2.5"
gem "activesupport", "~> 4.2.5"
gem "rake"
gem "dotenv"

# auth
gem "omniauth"
gem "omniauth-github"
gem "omniauth-twitter"
gem "omniauth-oauth2", "~> 1.3.1"
gem "sinatra"

# gem "sucker_punch", "~> 2.0"
gem "sidekiq", "~> 4.0"
gem "redis-namespace"

gem "arproxy"
# gem "puma"
gem "unicorn"
gem 'unicorn-worker-killer', require: "unicorn/worker_killer"

group :test, :development do
  gem "pry"
  gem "rerun"
end

group :development do
  gem "capistrano", "~> 3.4"
  gem 'capistrano-rbenv', '~> 2.0'
  gem 'capistrano3-unicorn', '0.2.1'
  gem 'capistrano-bundler', '~> 1.1.2'
end

group :test do
  # gem "database_cleaner"
  gem "rspec", "~> 3.4.0"
  gem "timecop"
  gem "rack-test"
  gem "capybara"
end

group :production do
end
