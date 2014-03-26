# source "http://rubygems.org"
source "http://ruby.taobao.org"

gem "sinatra",              "~> 1.4.4"
gem "sinatra-activerecord", "~> 1.4.0"

# sinatra-contrib不能直接require，否则会导致与sinatra-activerecord的namespace冲突
gem "sinatra-contrib",  "~> 1.4.2", require: false

gem "activesupport",    "~> 4.0.3", require: "active_support/all"

gem "rack-flash3"
gem "rack_csrf"
gem "rake"
gem "sqlite3"
gem "mysql2"
gem "slim"
gem "multi_json"
gem "uglifier"
gem "yui-compressor"
gem "awesome_print"
gem "sanitize"

gem "rainbows"
gem "capistrano",       "~> 3.1.0"
gem "capistrano-bundler"
gem 'rvm1-capistrano3', require: false

group :development do
  gem "thin"
  gem "tux"
end

group :test do
end
