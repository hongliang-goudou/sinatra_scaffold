# config valid only for Capistrano 3.1
lock '3.1.0'

set :application,       "sinatra_scaffold"
set :repo_url,          "https://github.com/hongliang-goudou/sinatra_scaffold.git"
set :scm,               :git
set :branch,            :master
set :deploy_via,        :remote_cache
set :copy_exclude,      [".git"]
set :linked_files,      %w{config/database.rb}
set :linked_dirs,       %w{}
set :keep_releases,     15
set :unicorn_pid,       "/tmp/unicorn_#{fetch(:application)}.pid"
set :rvm1_ruby_version, "2.1.1"

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

namespace :deploy do

  desc "Bundle install"
  task :bundle do
    on roles(:app) do
      within release_path do
        execute :bundle, "install"
      end
    end
  end

  desc "Migrate"
  task :migrate do
    on roles(:app) do
      within release_path do
        execute :bundle, "exec rake db:migrate"
      end
    end
  end

  desc "Precompile"
  task :precompile do
    on roles(:app) do
      within release_path do
        execute :bundle, "exec rake precompile"
      end
    end
  end

  desc "Start rainbows"
  task :start do
    on roles(:app) do
      within release_path do
        execute :bundle, "exec rainbows -c config/unicorn.rb -E production -D config.ru"
      end
    end
  end

  desc "Stop rainbows"
  task :stop do
    pid = fetch(:unicorn_pid)
    on roles(:app) do
      execute "if [ -f #{pid} ]; then kill -QUIT `cat #{pid}`; fi"
    end
  end

  desc "Restart rainbows"
  task :restart do
    pid = fetch(:unicorn_pid)
    on roles(:app) do
      execute "if [ -f #{pid} ]; then kill -USR2 `cat #{pid}`; fi"
    end
  end

  after :updating,   :bundle
  after :updating,   :migrate
  after :updating,   :precompile
  after :publishing, :restart

end
