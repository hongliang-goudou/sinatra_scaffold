worker_processes 4

Rainbows! do
  use                       :ThreadSpawn
  worker_connections        100
  keepalive_timeout         0
  keepalive_requests        100
  client_max_body_size      5*1024*1024
  client_header_buffer_size 2*1024
end

# 注意日志文件是在/var/log/nginx下，目录权限要可写
log_path     = "/var/log/nginx"
app_root     = File.expand_path("../../", __FILE__)
app_basename = File.basename(app_root)

working_directory app_root

# 监听本地socket端口，再监听9292端口
listen "/tmp/unicorn_#{app_basename}.sock", backlog: 64
listen 9292, tcp_nopush: false

# Nuke workers after 30 seconds instead of 60 seconds (the default)
timeout 30

# App PID
pid "/tmp/unicorn_#{app_basename}.pid"

# By default, the Unicorn logger will write to stderr.
# Additionally, some applications/frameworks log to stderr or stdout,
# so prevent them from going to /dev/null when daemonized here:
stdout_path File.join(log_path, "unicorn_#{app_basename}.stdout.log") if log_path
stderr_path File.join(log_path, "unicorn_#{app_basename}.stderr.log") if log_path

# To save some memory and improve performance
preload_app true
GC.copy_on_write_friendly = true if GC.respond_to?(:copy_on_write_friendly=)

# Force the bundler gemfile environment variable to
# reference the Сapistrano "current" symlink
before_exec do |_|
  ENV["BUNDLE_GEMFILE"] = File.join(app_root, 'Gemfile')
end

before_fork do |server, worker|
  # 参考 http://unicorn.bogomips.org/SIGNALS.html
  # 使用USR2信号，以及在进程完成后用QUIT信号来实现无缝重启
  old_pid = "/tmp/unicorn_#{app_basename}.pid.oldbin"
  if File.exists?(old_pid) && server.pid != old_pid
    begin
      Process.kill("QUIT", File.read(old_pid).to_i)
    rescue Errno::ENOENT, Errno::ESRCH
      # someone else did our job for us
    end
  end

  # the following is highly recomended for Rails + "preload_app true"
  # as there's no need for the master process to hold a connection
  ActiveRecord::Base.connection.disconnect! if defined?(ActiveRecord::Base)
end

after_fork do |server, worker|
  # 禁止GC，配合后续的OOB，来减少请求的执行时间
  # GC.disable

  # the following is *required* for Rails + "preload_app true",
  # ActiveRecord::Base.establish_connection if defined?(ActiveRecord::Base)
  # 由于使用了sinatra-activerecord，所以只要调用一下Sinatra::Application的database方法就可以建立数据库连接了
  Sinatra::Application.database if defined?(ActiveRecord::Base)
end
