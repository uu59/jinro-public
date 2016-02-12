root = ENV["APP_ROOT"] ? Pathname.new(ENV["APP_ROOT"]) : Pathname.new(__FILE__).dirname.parent
root.join("log").mkpath

working_directory root.to_s
pid               root.join("tmp/pids/unicorn.pid").to_s


stderr_path root.join("log/unicorn.stderr.log").to_s
stdout_path root.join("log/unicorn.stdout.log").to_s

worker_processes 3
listen 9292
preload_app true


before_exec do |server|
  # http://qiita.com/tachiba/items/7eef03cce6a917a957dc
  ENV['BUNDLE_GEMFILE'] = root.join("Gemfile").to_s
end

before_fork do |server, worker|
  # the following is highly recomended for Rails + "preload_app true"
  # as there's no need for the master process to hold a connection
  if defined?(ActiveRecord::Base)
    ActiveRecord::Base.connection.disconnect!
  end

  # Before forking, kill the master process that belongs to the .oldbin PID.
  # This enables 0 downtime deploys.
  old_pid = "#{server.config[:pid]}.oldbin"
  if File.exists?(old_pid) && server.pid != old_pid
    begin
      Process.kill("QUIT", File.read(old_pid).to_i)
    rescue Errno::ENOENT, Errno::ESRCH
      # someone else did our job for us
    end
  end
end

after_fork do |server, worker|
  if defined?(ActiveRecord::Base)
    # ActiveRecord::Base.establish_connection
  end
end
