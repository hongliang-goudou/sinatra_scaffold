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

启动方法：

1、执行```rackup```即可，默认端口9292，可使用```rackup -p 4567```来改变端口
2、执行```ruby app.rb```也行，默认端口4567，可使用```ruby app.rb -p 9292```来改变端口

命令行调试：

1、执行```tux```
2、如果要用pry，则执行```pry -r ./app```，注意一定要带上"./"

DB Migration建立方法：
```rake db:create_migration NAME=xxxxxx```
然后在db/migrate目录下即可找到migrate文件。其他rake用法可以执行```rake -T```查看

生产环境：
执行```rackup -E production```可以在生产环境下启动Thin
