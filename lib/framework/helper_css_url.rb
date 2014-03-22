# 定义css_url helper
helpers do
  # 引用css文件的路径计算，对未处理过的css文件使用yui-compressor处理
  # 传入的参数为不含/css路径前缀和.css扩展名后缀的字符串，如bootstrap
  # 前端页面用法：
  #
  #   link rel="stylesheet" type="text/css" href=css_url("bootstrap")
  #
  def css_url(basename)
    basename = basename[0..-4] if uri.end_with?(".css")
    uri      = "/css/#{basename}.css"

    if Sinatra::Application.production? || (Sinatra::Application.respond_to?(:compress_css) && Sinatra::Application.compress_css)
      basedir  = File.join(Sinatra::Application.root, "public")
      filepath = File.join(basedir, "css", "#{basename}.css")
      uri      = YUIHelper.compress_file(filepath)[basedir.length..-1] if File.exists?(filepath)
    end

    uri
  end
end
