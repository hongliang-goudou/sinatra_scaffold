# 定义js_url helper
helpers do
  # 引用js文件的路径计算，对未处理过的js文件使用uglifier处理
  # 传入的参数为不含/js路径前缀和.js扩展名后缀的字符串，如jquery
  # 前端页面用法：
  #
  #   script src=js_url("jquery")
  #
  def js_url(basename)
    basename = basename[0..-4] if uri.end_with?(".js")
    uri      = "/js/#{basename}.js"

    if Sinatra::Application.production? || (Sinatra::Application.respond_to?(:compress_js) && Sinatra::Application.compress_js)
      basedir  = File.join(Sinatra::Application.root, "public")
      filepath = File.join(basedir, "js", "#{basename}.js")
      uri      = UglifierHelper.compress_file(filepath)[basedir.length..-1] if File.exists?(filepath)
    end

    uri
  end
end
