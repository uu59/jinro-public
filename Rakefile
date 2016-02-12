require_relative "./app/api.rb"

namespace :db do
  desc "create"
  task :create do
    ActiveRecord::Base.establish_connection App.database.merge("database" => nil)
    begin
    ActiveRecord::Base.connection.create_database App.database["database"]
    rescue ActiveRecord::StatementInvalid => e
      raise e unless e.message.match(/already exists/)
    end
  end

  desc "drop"
  task :drop do
    ActiveRecord::Base.establish_connection App.database.merge("database" => nil)
    ActiveRecord::Base.connection.drop_database App.database["database"]
  end

  desc "drop, create, migrate"
  task :reset do
    Rake::Task["db:drop"].invoke
    Rake::Task["db:create"].invoke
    ActiveRecord::Base.establish_connection App.database
    Rake::Task["db:migrate"].invoke
  end

  desc "migration"
  task :migrate do
    # TODO yml統合
    Tempfile.create("foo.yml") do |f|
      f.write App.database.to_yaml
      f.rewind
      puts `cat #{f.path}`
      system ENV, "bundle exec ridgepole -c #{f.path} --apply"
    end
  end

  desc "migration (dry run)"
  task :"migrate:dryrun" do
    system ENV, "bundle exec ridgepole -c config/database.yml --apply --dry-run"
  end

end

namespace :app do
  desc "start reverse proxy server (for development)"
  task :"start:dev_rp" do
    sh "bundle exec rerun -n nginx -b -d config/ -p nginx.conf -- $HOME/opt/nginx/sbin/nginx -p . -c ./config/nginx.conf"
  end

  desc "start sidekiq"
  task :"start:dev_sidekiq" do
    sh "bundle exec rerun -n sidekiq -b -d app/ -d config/ -p '**/*.{rb,ru,yml}' -- bundle exec sidekiq -r ./config/boot.rb -C config/sidekiq.yml"
  end

  desc "start server (for development)"
  task :"start:dev_api" do
    sh "bundle exec rerun -n api -b -d app/ -d config/ -p '**/*.{rb,ru}' -- bundle exec unicorn -E development -c config/unicorn.rb config/rackup.ru"
  end

  desc "start watch js (for development)"
  task :"start:dev_js" do
    sh "cd js;npm run dev"
  end

  desc "start watch js (for development)"
  multitask :dev => %w(start:dev_api start:dev_js start:dev_rp start:dev_sidekiq)
end

# Based on: https://gist.github.com/oivoodoo/5089237
desc "Print routes for API"
task :routes do
  mapped_prefix = "/api"
  format = "%<method>7s %<path>-32s | %<param_keys>-20s | %<description>s"
  puts "\x1b[4m" + format % {
    method: "Method",
    path: "          Path",
    param_keys: "Parameters",
    description: "Description",
  } + "\x1b[0m"
  App::API.routes.each do |route|
    info = route.instance_variable_get :@options
    info[:path] = "#{mapped_prefix}#{info[:path].gsub(/:version/, info[:version]).gsub("(.json)", "")}"
    info[:param_keys] = info[:params].keys.join(", ")
    info[:param_count] = info[:params].keys.length
    info[:description] ||= ""
    output = format % info
    puts output.gsub(%r#(:[a-zA-Z0-9_]+)#, "\x1b[1m\\1\x1b[0m")
  end
end

namespace :create do
  desc "create archive for room"
  task :archive do
    room_id = ENV["ROOM_ID"].to_s
    room = Room.find(room_id)

    # TODO: モデルに集約するとかしてなんとかする
    members = room.members(with_role: true)
    room_info = room.to_json_hash.merge(
      personalInfo: room.current_information_for(nil)
    )
    messages = room.messages
    json = MultiJson.dump({
      room: room_info,
      members: members,
      chatLogs: messages,
    })
    archive_root = App.root.join("js/archive")
    json_path = archive_root.join("#{room.id}.json")
    json_path.write(json)
    
    html_path = archive_root.join("#{room.id}.html")
    sh "cd js && npm run create:archive -- #{room_id}"
    sh "gzip -c #{html_path} > #{html_path}.gz"
    room.clear_chat_log
  end
end

desc "Run rspec"
task :spec do
  # TODO: Support `SPEC=... SPEC_OPTS=... rake spec` ?
  ENV["RACK_ENV"] = "test"
  Rake::Task["db:reset"].invoke
  system "bundle exec rspec"
end

desc "a"
task :build_assets do
  sh "cd js && npm run build && cd .. && tar cvhf assets.tar.gz js/build/ public/"
end
