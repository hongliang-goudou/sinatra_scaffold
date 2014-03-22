# 使用uglifier对js文件做压缩处理
module UglifierHelper
  @@uglifier = Uglifier.new(output: { comments: :none })

  # 传入js字符串，返回压缩后的内容
  def self.compress_content(str)
    @@uglifier.compile(str)
  end

  # 处理单个js文件，传入文件完整路径，返回处理后的文件完整路径
  def self.compress_file(filepath)
    md5      = Digest::MD5.hexdigest(File.read(filepath))
    basedir  = File.join(File.dirname(filepath), "_")
    basename = File.basename(filepath).split(".").insert(-2, "v#{md5}").join(".")
    newpath  = File.join(basedir, basename)

    # 看看是否存在已经处理过的js文件，不存在的话需要uglifier处理一下
    unless File.exists?(newpath)
      ap "compressing #{filepath} -=> #{File.basename(newpath)}"

      # 删掉所有原来生成过的js文件
      File.delete(*Dir[filepath.split(".").insert(-2, "v*").join(".") + "*"])

      # uglifier处理并将结果写入文件
      result = compress_content(File.read(filepath))

      Dir.mkdir(basedir) unless Dir.exists?(basedir)
      File.write(newpath, result)
      Zlib::GzipWriter.open("#{newpath}.gz") { |gz| gz.write(result) }
    end

    newpath
  end

  # 对public/js目录下的所有js文件做处理
  def self.compress_all_file
    Dir[File.join(Sinatra::Application.root, "public/js/**/*.js")].reject do |filepath|
      # /js/_/目录存放的是生成后的文件，不需要处理
      filepath["/_/"]

    end.each do |filepath|
      compress_file(filepath)
    end
  end
end
