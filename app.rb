require "bundler"
require "sinatra"
require "sinatra/reloader" if Sinatra::Application.development?

# 用bundler加载所有用到的gem
Bundler.require :default, Sinatra::Application.environment

# 定义数据库位置
set :database, "sqlite3:///db/db.sqlite3" # mysql2://username:password@host/db

# 开发模式下是否开启js/css文件的compress
set :compress_js,   true
set :compress_css,  true

# 配置slim，全站均不使用layout机制
set :slim, {
  layout:         false,
  format:         :html5,
  pretty:         development?,
  sort_attrs:     false,
  use_html_safe:  true,
  streaming:      true,
}

# 引用项目中的其他.rb文件，更复杂的sinatra配置定义在lib/app_helper.rb中
Dir["#{__dir__}/**/*.rb"].reject do |file|
  # 根目录、db、public目录下的rb文件不引入
  f = file[(Sinatra::Application.root.length + 1)..-1]
  f.index("/").nil? || ["db", "public"].detect { |a| f.start_with?("#{a}/") }

end.each do |file|
  require file
  also_reload file if Sinatra::Application.development?
end
