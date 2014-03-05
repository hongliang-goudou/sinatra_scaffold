require ::File.expand_path("../app", __FILE__)
require "sinatra/activerecord/rake"

desc "对js/css文件做precompile"
task :precompile do
  UglifierHelper.precompile_all_js
end
