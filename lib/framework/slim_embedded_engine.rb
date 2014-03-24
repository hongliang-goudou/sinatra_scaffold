# 扩展slim本身对javascript和css的处理，使得嵌入模板中的js/css内容能够被自动压缩处理
module Slim
  class Embedded

    # 与slim_parser.rb配合，传进来的body最后一项是当前slim文件名，处理为相对路径文件名，将/替换为=
    def self.js_css_slim_file_path(body)
      return "" unless body.last.is_a?(Array) && body.last.length == 2 && body.last[0] == :static

      _, slim_file_path = body.last
      slim_file_path    = slim_file_path[Sinatra::Application.root.length..-1] if slim_file_path.start_with?(Sinatra::Application.root)
      slim_file_path    = slim_file_path[5..-1] if slim_file_path.start_with?("/app/")

      slim_file_path.gsub!("/", "=")
      slim_file_path.gsub!(".slim", "")

      slim_file_path
    end

    # 在开发模式下，对当前slim模板嵌入的js/css片断文件按atime排序，找到atime值间隔超过10秒的两个文件，删除后面的所有文件
    # 这个逻辑是为了防止在开发模式下反复修改代码导致垃圾文件过多，通过大间隔的atime值来区分哪些是正在用的、哪些是以前的旧代码
    def self.delete_unused_partial_js_css_files(ext, slim_file_path)
      return unless Sinatra::Application.development?

      hash    = {}
      basedir = File.join(Sinatra::Application.root, "public", ext.to_s, "_")
      files   = Dir[File.join(basedir, "#{slim_file_path}=v*.#{ext}")].sort_by do |f|
        hash[f] = File.atime(f).to_i * -1
      end

      files.each_with_index do |f, i|
        next if files[i+1].nil?

        if hash[files[i+1]] - hash[f] >= 10
          # 找到断点了，删掉断点之后的所有文件，包括.gz文件
          File.delete(*files[(i+1)..-1].map { |f| "#{f}.gz"} ) rescue nil
          File.delete(*files[(i+1)..-1]) rescue nil
          break
        end
      end
    end

    # 替换原JavaScriptEngine
    class JavaScriptUglifierEngine < Engine
      disable_option_validator!

      def on_slim_embedded(engine, body)
        # 仅仅在生产环境、或者明确开启了压缩JS开关的情况下才做
        unless Sinatra::Application.production? || Sinatra::Application.try(:compress_js)
          return [:static, "<script>\n#{collect_text(body)}\n</script>\n"]
        end

        # 得到当前的slim模板文件名
        slim_file_path = Slim::Embedded.js_css_slim_file_path(body)

        # 根据这段js内容的md5值来判断内容是否已经被缓存过和压缩过
        content  = collect_text(body)
        md5      = Digest::MD5.hexdigest(content)
        basedir  = File.join(Sinatra::Application.root, "public", "js", "_")
        basename = "#{slim_file_path}=v#{md5}.js"
        md5path  = File.join(basedir, basename)

        # 如果该段js内容的缓存文件还不存在，压缩该js片断，创建一份缓存文件
        if File.exists?(md5path)
          compiled = File.read(md5path)

        else
          compiled = UglifierHelper.compress_content(content)

          # 删掉多余的垃圾文件
          Slim::Embedded.delete_unused_partial_js_css_files(:js, slim_file_path)

          # 生成新文件
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

    # 替换原CSS的TagEngine
    class CssYUIEngine < Engine
      disable_option_validator!

      def on_slim_embedded(engine, body)
        # 仅仅在生产环境、或者明确开启了压缩CSS开关的情况下才做
        unless Sinatra::Application.production? || Sinatra::Application.try(:compress_css)
          return [:static, "\n<style>\n#{collect_text(body)}\n</style>"]
        end

        # 得到当前的slim模板文件名
        slim_file_path = Slim::Embedded.js_css_slim_file_path(body)

        # 根据这段css内容的md5值来判断内容是否已经被缓存过和压缩过
        content  = collect_text(body)
        md5      = Digest::MD5.hexdigest(content)
        basedir  = File.join(Sinatra::Application.root, "public", "css", "_")
        basename = "#{slim_file_path}=v#{md5}.css"
        md5path  = File.join(basedir, basename)

        # 如果该段css内容的缓存文件还不存在，压缩该css片断，创建一份缓存文件
        if File.exists?(md5path)
          compiled = File.read(md5path)

        else
          compiled = YUIHelper.compress_content(content)

          # 删掉多余的垃圾文件
          Slim::Embedded.delete_unused_partial_js_css_files(:css, slim_file_path)

          # 生成新文件
          Dir.mkdir(basedir) unless Dir.exists?(basedir)
          File.write(md5path, compiled)
          Zlib::GzipWriter.open("#{md5path}.gz") { |gz| gz.write(compiled) }
        end

        # css片断长度超过500字节则视为内容过长，需要改为文件引用方式，而非内嵌到html中
        if content.length > 500
          [:static, "\n<link rel=\"stylesheet\" type=\"text/css\" href=\"/css/_/#{basename}\">"]

        else
          [:static, "\n<style>#{compiled}</style>"]
        end
      end
    end

    register :javascript, JavaScriptUglifierEngine
    register :css,        CssYUIEngine
  end
end
