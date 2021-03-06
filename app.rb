require "bundler"
require "sinatra"
require "sinatra/reloader" if Sinatra::Application.development?
require "sinatra/cookies"
require "sinatra/json"
require "rack-flash"
require "rack/csrf"
require "sanitize"
require "json"

# 用bundler加载所有用到的gem
Bundler.require :default,   Sinatra::Application.environment

# 定义数据库位置，因为涉及到用户名和密码，故引入config/database.rb文件，该文件不进入git库管理
require File.join(Sinatra::Application.root, "/config/database.rb")

# session相关配置
set :session_secret,        "11e89ee74e7679201c1f0eeab8a66c27"
use Rack::Session::Cookie,  expire_after: 2592000, secret: Sinatra::Application.session_secret
use Rack::Flash,            sweep: true

# csrf
use Rack::Csrf,             raise: Sinatra::Application.development?

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
Dir[File.join(Sinatra::Application.root, "**/*.rb")].reject do |file|
  # 根目录、config、db、public目录下的rb文件不引入
  f = file[(Sinatra::Application.root.length + 1)..-1]
  f.index("/").nil? || ["config", "db", "public"].detect { |a| f.start_with?("#{a}/") }

end.each do |file|
  require file
  also_reload file if Sinatra::Application.development?
end
