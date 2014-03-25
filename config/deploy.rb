# config valid only for Capistrano 3.1
lock '3.1.0'

set :application,   File.basename(File.expand_path("../../", __FILE__))
set :repo_url,      "https://github.com/hongliang-goudou/sinatra_scaffold.git"
set :scm,           :git
set :branch,        :master
set :deploy_via,    :remote_cache
set :copy_exclude,  [".git"]
set :linked_files,  %w{config/database.rb}
set :linked_dirs,   %w{}
set :keep_releases, 15

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

namespace :deploy do

  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      # Your restart mechanism here, for example:
      # execute :touch, release_path.join('tmp/restart.txt')
    end
  end

  after :publishing, :restart

  after :restart, :clear_cache do
    on roles(:web), in: :groups, limit: 3, wait: 10 do
      # Here we can do anything such as:
      # within release_path do
      #   execute :rake, 'cache:clear'
      # end
    end
  end

end

# namespace :deploy do
#   desc "Start rainbows"
#   task :start do
#     on roles :app do
#       within release_path do
#         with rails_env: fetch(:rails_env) do
#           execute :bundle, "exec rainbows -c #{fetch(:unicorn_config)} -D #{fetch(:rackup_file)}"
#         end
#       end
#     end
#   end

#   desc "Stop rainbows"
#   task :stop do
#     pid = fetch(:unicorn_pid)
#     on roles :app do
#       execute "if [ -f #{pid} ]; then kill -QUIT `cat #{pid}`; fi"
#     end
#   end

#   desc "Restart rainbows"
#   task :restart do
#     pid = fetch(:unicorn_pid)
#     on roles :app do
#       execute "if [ -f #{pid} ]; then kill -USR2 `cat #{pid}`; fi"
#     end
#   end

#   namespace :db do
#     desc "rake db:seed"
#     task :seed do
#       on roles :app do
#         within release_path do
#           with rails_env: fetch(:rails_env) do
#             execute :rake, "db:seed"
#           end
#         end
#       end
#     end
#   end
# end
