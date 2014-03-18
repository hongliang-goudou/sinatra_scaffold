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
  @@uglifier = Uglifier.new(output: { comments: :none })

  # 传入js字符串，返回压缩后的内容
  def self.precompile_js_content(str)
    @@uglifier.compile(str)
  end

  # 处理单个js文件，传入文件完整路径，返回处理后的文件完整路径
  def self.precompile_js(filepath)
    md5      = Digest::MD5.hexdigest(File.read(filepath))
    basedir  = File.join(File.dirname(filepath), "_")
    basename = File.basename(filepath).split(".").insert(-2, "v#{md5}").join(".")
    newpath  = File.join(basedir, basename)

    # 看看是否存在已经处理过的js文件，不存在的话需要uglifier处理一下
    unless File.exists?(newpath)
      ap "compiling #{filepath} -=> #{File.basename(newpath)}"

      # 删掉所有原来生成过的js文件
      File.delete(*Dir[filepath.split(".").insert(-2, "v*").join(".") + "*"])

      # uglifier处理并将结果写入文件
      result = precompile_js_content(File.read(filepath))

      Dir.mkdir(basedir) unless Dir.exists?(basedir)
      File.write(newpath, result)
      Zlib::GzipWriter.open("#{newpath}.gz") { |gz| gz.write(result) }
    end

    newpath
  end

  # 对public/js目录下的所有js文件做处理
  def self.precompile_all_js
    Dir[File.join(Sinatra::Application.settings.root, "public/js/**/*.js")].reject do |filepath|
      # /js/_/目录存放的是生成后的文件，不需要处理
      filepath["/_/"]

    end.each do |filepath|
      self.precompile_js(filepath)
    end
  end
end

# 扩展slim本身对javascript和css的处理，使得嵌入模板中的js/css内容能够被自动压缩处理
module Slim
  class Embedded
    class JavaScriptUglifierEngine < Engine
      disable_option_validator!

      def on_slim_embedded(engine, body)
        # 根据这段js内容的md5值来判断内容是否已经被缓存过和压缩过
        content  = collect_text(body)
        md5      = Digest::MD5.hexdigest(content)
        basedir  = File.join(Sinatra::Application.settings.root, "public", "js", "_")
        basename = "v#{md5}.js"
        md5path  = File.join(basedir, basename)

        # 如果该段js内容的缓存文件还不存在，压缩该js片断，创建一份缓存文件
        if File.exists?(md5path)
          compiled = File.read(md5path)

        else
          compiled = UglifierHelper.precompile_js_content(content)

          Dir.mkdir(basedir) unless Dir.exists?(basedir)
          File.write(md5path, compiled)
          Zlib::GzipWriter.open("#{md5path}.gz") { |gz| gz.write(compiled) }
        end

        # js片断长度超过500字节则视为内容过长，需要改为文件引用方式，而非内嵌到html中
        if content.length > 500
          [:static, "<script src=\"/js/_/#{basename}\"></script>\n"]

        else
          [:static, "<script>#{compiled}</script>\n"]
        end
      end
    end

    register :javascript, JavaScriptUglifierEngine
  end
end

# 定义js_url、css_url等helper
helpers do
  # 引用js文件的路径计算，对未处理过的js文件使用uglifier处理
  # 传入的参数为不含/js路径前缀和.js扩展名后缀的字符串，如jquery
  # 前端页面用法：script src=js_url("jquery")
  def js_url(basename)
    basename = basename[0..-4] if uri.end_with?(".js")
    uri      = "/js/#{basename}.js"

    if Sinatra::Application.production? || Sinatra::Application.settings.precompile
      basedir  = File.join(Sinatra::Application.settings.root, "public")
      filepath = File.join(basedir, "js", "#{basename}.js")
      uri      = UglifierHelper.precompile_js(filepath)[basedir.length..-1] if File.exists?(filepath)
    end

    uri
  end
end
