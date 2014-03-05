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

# 使用uglifier对js文件做压缩处理
module UglifierHelper
  # 处理单个js文件，传入文件完整路径，返回处理后的文件完整路径
  def precompile_js(filepath)
    md5     = Digest::MD5.hexdigest(File.read(filepath))
    newpath = filepath.split(".").insert(-2, "v#{md5}").join(".")

    # 看看是否存在已经处理过的js文件，不存在的话需要uglifier处理一下
    unless File.exists?(newpath)
      ap "compiling #{filepath} -=> #{File.basename(newpath)}"

      # 删掉所有原来生成过的js文件
      File.delete(*Dir[filepath.split(".").insert(-2, "v*").join(".") + "*"])

      # uglifier处理并将结果写入文件
      result = Uglifier.compile(File.read(filepath), output: { comments: :none })
      File.write(newpath, result)

      # 再生成一份gzip压缩过的版本
      Zlib::GzipWriter.open("#{newpath}.gz") { |gz| gz.write(result) }
    end

    newpath
  end

  # 对public/js目录下的所有js文件做处理
  def precompile_all_js
    Dir[File.join(Sinatra::Application.settings.root, "public/js/**/*.js")].each do |filepath|
      v = filepath.split(".")[-2].to_s
      next if v.length == 33 && v[0] == "v"

      self.precompile_js(filepath)
    end
  end

  module_function :precompile_js, :precompile_all_js
end

helpers do
  # 引用js文件的uglifier处理，传入的参数为不含/js路径前缀和.js扩展名后缀的字符串，如jquery
  # 前端页面用法：== script "jquery"
  def script(basename)
    basename = basename[0..-4] if uri.end_with?(".js")
    uri      = "/js/#{basename}.js"

    if Sinatra::Application.production? || Sinatra::Application.settings.precompile
      basedir  = File.join(Sinatra::Application.settings.root, "public")
      filepath = File.join(basedir, "js", "#{basename}.js")
      uri      = UglifierHelper.precompile_js(filepath)[basedir.length..-1] if File.exists?(filepath)
    end

    "<script src=\"#{uri}\"></script>"
  end
end
