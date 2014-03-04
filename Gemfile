#source "http://rubygems.org"
source "http://ruby.taobao.org"

gem "sinatra",              "~> 1.4.4"
gem "sinatra-activerecord", "~> 1.4.0"

# sinatra-contrib不能整个直接require，否则会导致与sinatra-activerecord的namespace冲突
gem "sinatra-contrib", "~> 1.4.2", require: ["sinatra/reloader"]

gem "rake"
gem "sqlite3"
gem "mysql2"
gem "slim"

gem "awesome_print"

group :development do
  gem "thin"
  gem "tux" # 开发时使用tux来做命令行console环境比较方便
end

group :test do
end
