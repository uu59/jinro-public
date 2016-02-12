require_relative "./boot.rb"

use Unicorn::WorkerKiller::MaxRequests, 256, 1024, true
use Unicorn::WorkerKiller::Oom, (80*(1024**2)), (128*(1024**2)), 16, true

map "/auth" do
  OmniAuth.configure do |config|
    config.path_prefix = ""
  end
  use Rack::Session::Cookie, secret: SecureRandom.hex(32)
  use OmniAuth::Builder do
    provider :github, App.github_tokens[:token], App.github_tokens[:secret], scope: "user,read:org"
  end

  run App::Auth
end

map "/api" do
  run App::API
end

require 'sidekiq'
require 'sidekiq/web'
map "/sidekiq" do
  use Rack::Auth::Basic do |username, password|
    username == ENV["SIDEKIQ_BASIC_USER"] && password == ENV["SIDEKIQ_BASIC_PASS"]
  end
  run Sidekiq::Web
end
