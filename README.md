sinatra_scaffold
================

Sinatra搭建好了一切基础的空模板项目，包括以下修改：

- 使用sinatra-contrib/reloader来做开发环境的reload
- 使用bundler管理gem
- 使用slim模板
- 自定义slim模板文件的寻找路径，使得.slim文件与.rb文件可以在同一目录下
- db目录下存放ActiveRecord的migrate文件
- model目录下存放ActiveRecord的model文件
- lib目录下存放第三方库代码
- public目录下存放js/css/image等文件

### 启动方法：

1. 执行```rackup```即可，默认端口9292，可使用```rackup -p 4567```来改变端口
2. 执行```ruby app.rb```也行，默认端口4567，可使用```ruby app.rb -p 9292```来改变端口

### 命令行调试：

1. 执行```tux```
2. 如果要用pry，则执行```pry -r ./app```，注意一定要带上```./```

### DB Migration建立方法：

```rake db:create_migration NAME=xxxxxx```

然后在db/migrate目录下即可找到migrate文件。其他rake用法可以执行```rake -T```查看

###生产环境：

执行```rackup -E production```可以在生产环境下启动Thin

###cookie
读取cookie狠简单，在.rb和.slim中可以直接使用```cookies[:test]```来读取cookie内容

写入cookie使用```response.set_cookie(:test, value: "test123-value", path: "/", max_age: "3600")```这样的形式即可，***特别注意path要显性设置为```/```***

###session
直接在.rb和.slim中使用```session[:test]```即可存取session，session的使用方式和expire时间在```app.rb```中定义

###flash
flash的用法与Rails一样，可以用```flash[:notice]```和```flash.now[:notice]```这样的形式来读取flash内容。在```app.rb```中默认配置为flash的行为是仅保留一个请求周期

###sanitize
```Sanitize.clean("<html>...</html>")

###csrf
```Rack::Csrf.csrf_metatag(env)```
```Rack::Csrf.csrf_tag(env)```
```Rack::Csrf.csrf_token(env)```
