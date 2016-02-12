# config valid only for current version of Capistrano
lock '3.4.0'

set :application, 'jinro'
set :repo_url, 'git@github.com:uu59/jinro.git'

# Default branch is :master
# ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp
set :branch, "jinro"

set :scm, :git
set :format, :pretty
set :log_level, :debug
set :pty, true
set :linked_files, fetch(:linked_files, []).concat(
  %w(
    config/database.yml .env
  )
)

# Default value for linked_dirs is []
set :linked_dirs, fetch(:linked_dirs, []).concat(
  %w(
    log tmp/pids tmp/cache tmp/sockets
    js/node_modules js/archive
  )
)

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

set :keep_releases, 5

set :rack_env, "production"
# set :puma_conf, -> { "#{shared_path}/config/puma.rb" }
# set :puma_pid, -> { "#{shared_path}/tmp/pids/puma.pid" }

#set :default_env, {
#  RACK_ENV: "production",
#}
set :unicorn_config_path, -> { "#{current_path}/config/unicorn.rb" }
set :unicorn_rack_env, -> { "production" } # apply to unicorn as "none"
set :unicorn_options, -> { "#{current_path}/config/rackup.ru" }

set :nodebrew_node_version, "4.3.1"

namespace :deploy do
  after :restart, :clear_cache do
    on roles(:web), in: :groups, limit: 3, wait: 10 do
      invoke "unicorn:restart"
    end
  end

  namespace :db do
    %i(create migrate migrate:dryrun).each do |cmd|
      task cmd do
        on roles %w(app) do
          within release_path do
            with rack_env: fetch(:rack_env) do
              rake "db:#{cmd}"
            end
          end
        end
      end
    end

    after "updated", "db:create"
    after "db:create", "db:migrate"
  end

  namespace :sidekiq do
    task :start do
      on roles %w(app) do
        within release_path do
          execute :bundle, "exec sidekiq -r ./config/boot.rb -C config/sidekiq.yml -d"
        end
      end
    end

    task :usr1 do
      on roles %w(app) do
        within release_path do
          pidfile = "#{current_path}/tmp/sidekiq.pid"
          if File.exists?(pidfile)
            pid = File.read(pidfile).strip
            execute "kill -USR1 #{pid}"
          end
        end
      end
    end

    task :stop do
      on roles %w(app) do
        within release_path do
          pidfile = "#{current_path}/tmp/sidekiq.pid"
          if File.exists?(pidfile)
            pid = File.read(pidfile).strip
            execute "kill -0 #{pid} && kill -TERM #{pid}"
          end
        end
      end
    end

    task :restart do
      invoke "deploy:sidekiq:stop"
      invoke "deploy:sidekiq:start"
    end
  end

  after "deploy:finished", "unicorn:restart"
  after "deploy:finished", "deploy:sidekiq:usr1"
  after "unicorn:restart", "deploy:sidekiq:restart"
end

namespace :npm do
  task :install_node do
    on roles %w(app) do
      unless test(:nodebrew, "ls | grep -q -F #{fetch(:nodebrew_node_version)}")
        execute :nodebrew, "install-binary #{fetch(:nodebrew_node_version)}"
      end
    end
  end

  task :install do
    on roles %w(app) do
      within "#{release_path}/js" do
        execute :nodebrew, "exec #{fetch(:nodebrew_node_version)} -- npm install --silent --no-spin --production"
      end
    end
  end

  task :build_assets_old do
    on roles %w(app) do
      within "#{release_path}/js" do
        execute :nodebrew, "exec #{fetch(:nodebrew_node_version)} -- npm run build"
      end
    end
  end

  task :build_assets do
    on roles(:all) do
      system "bundle exec rake build_assets"
      upload! "assets.tar.gz", "#{release_path}/assets.tar.gz"
      within release_path do
        execute :tar, "xvf assets.tar.gz"
      end
    end
  end

  namespace :stream do
    %i(start stop restart).each do |cmd|
      task cmd do
        on roles %w(app) do
          within "#{release_path}/js" do
            execute :nodebrew, "exec #{fetch(:nodebrew_node_version)} -- npm run stream:#{cmd}"
          end
        end
      end
    end
  end

  before "install", "install_node"
  after "deploy:updated", "install"
  after "deploy:updated", "build_assets"
  after "build_assets", "stream:restart"
end
