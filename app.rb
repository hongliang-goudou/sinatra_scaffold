# 定义数据库位置
# set :database, "mysql2://user:password@host/db"
set :database, "sqlite3:///db/dev.sqlite3"

# 定义App类，本文件力争做到通用，新项目一般不需要修改本类及以下代码
class App < Sinatra::Base

  # 注册需要的扩展
  register Sinatra::ActiveRecordExtension

  # 注册开发环境下的特殊扩展，如reloader
  configure :development do
    register Sinatra::Reloader
  end

  # 定义我们自己的模板查找机制，使得controller和view文件可以在同一目录下
  # 若URI为/abc/def/ghi，则模板文件可以在app/abc/def/ghi这四个目录中的任意一级下
  # 若URI为/admin/abc/def/ghi，且存在与app同级的admin根目录，则不会再去app目录下寻找
  helpers do
    def find_template(views, name, engine, &block)
      paths     = []
      parent    = ""
      path_info = request.path_info
      root_uri  = path_info.split("/")[1]

      # 判断URI请求是否为与app目录同级，同时将/db等特殊目录排除在外
      if ["", "db", "model", "lib", "public"].include?(root_uri) || !Dir.exists?(File.join(settings.root, root_uri))
        app_name  = "app"
      else
        app_name  = root_uri
        path_info = "/" + path_info.split("/")[2..-1].join("/")
      end

      # 根据URI一层一层向上指定要寻找的目录，直到app或同级目录为止
      begin
        result = File.expand_path(parent, path_info)
        parent = "../#{parent}"
        paths.push(File.join(settings.root, app_name, result))
      end until result == "/"

      [*paths, *views].each { |v| super(v, name, engine, &block) }
    end
  end

end

# 引用项目中的其他.rb文件
Dir["#{__dir__}/**/*.rb"].each do |file|
  f = file[(__dir__.length + 1)..-1]
  require file unless f.index("/").nil? || ["db", "public"].detect { |a| f.start_with?("#{a}/") }
end
