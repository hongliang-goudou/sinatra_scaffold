require ::File.expand_path("../app", __FILE__)
require "sinatra/activerecord/rake"

desc "对js/css目录下的文件做压缩处理"
task :precompile do
  UglifierHelper.compress_all_file
  YUIHelper.compress_all_file
end
