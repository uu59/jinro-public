server "jinro.uu59.org", user: "jinro", roles: %w(app db web)
set :branch, "jinro"

set :rbenv_type, :user # or :system, depends on your rbenv setup
set :rbenv_ruby, '2.3.0'

set :deploy_to, "/home/jinro/apps/el"

set :default_env, {
  NODEBREW_ROOT: "/opt/nodebrew",
  PATH: "/opt/nodebrew/current/bin:$PATH",
  APP_ROOT: "/home/jinro/apps/prod/current",
  RACK_ENV: "production",
}
