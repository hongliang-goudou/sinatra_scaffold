# 使用YUICompressor对css做压缩处理
module YUIHelper
  @@yui = YUI::CssCompressor.new

  def self.compress_content(str)
    # 压缩时强制把/*!...*/版权信息删掉
    str.gsub!("/*!", "/*")

    @@yui.compress(str)
  end

  # 处理单个css文件，传入文件完整路径，返回处理后的文件完整路径
  def self.compress_file(filepath)
    md5      = Digest::MD5.hexdigest(File.read(filepath))
    basedir  = File.join(File.dirname(filepath), "_")
    basename = File.basename(filepath).split(".").insert(-2, "v#{md5}").join(".")
    newpath  = File.join(basedir, basename)

    # 看看是否存在已经处理过的css文件，不存在的话就压缩处理一下
    unless File.exists?(newpath)
      ap "compressing #{filepath} -=> #{File.basename(newpath)}"

      # 删掉所有原来生成过的css文件
      File.delete(*Dir[filepath.split(".").insert(-2, "v*").join(".") + "*"])

      # yui-compressor处理并将结果写入文件
      result = compress_content(File.read(filepath))

      Dir.mkdir(basedir) unless Dir.exists?(basedir)
      File.write(newpath, result)
      Zlib::GzipWriter.open("#{newpath}.gz") { |gz| gz.write(result) }
    end

    newpath
  end

  # 对public/css目录下的所有css文件做处理
  def self.compress_all_file
    Dir[File.join(Sinatra::Application.root, "public/css/**/*.css")].reject do |filepath|
      # /js/_/目录存放的是生成后的文件，不需要处理
      filepath["/_/"]

    end.each do |filepath|
      compress_file(filepath)
    end
  end
end
