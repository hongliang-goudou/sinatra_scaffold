# 扩展slim本身对javascript和css的处理，使得嵌入模板中的js/css内容能够被自动压缩处理
module Slim
  class Embedded
    # 替换原JavaScriptEngine
    class JavaScriptUglifierEngine < Engine
      disable_option_validator!

      def on_slim_embedded(engine, body)
        # 仅仅在生产环境、或者明确开启了压缩JS开关的情况下才做
        unless Sinatra::Application.production? || Sinatra::Application.try(:compress_js)
          return [:static, "<script>\n#{collect_text(body)}\n</script>\n"]
        end

        # 与slim_parser.rb配合，传进来的body最后一项是当前slim文件名，处理为相对路径文件名，将/替换为=
        _, slim_file_path = body.last
        slim_file_path    = slim_file_path[Sinatra::Application.root.length..-1] if slim_file_path.start_with?(Sinatra::Application.root)
        slim_file_path    = slim_file_path[5..-1] if slim_file_path.start_with?("/app/")
        slim_file_path.gsub!("/", "=").gsub!(".slim", "")

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

        # 与slim_parser.rb配合，传进来的body最后一项是当前slim文件名，处理为相对路径文件名，将/替换为=
        _, slim_file_path = body.last
        slim_file_path    = slim_file_path[Sinatra::Application.root.length..-1] if slim_file_path.start_with?(Sinatra::Application.root)
        slim_file_path    = slim_file_path[5..-1] if slim_file_path.start_with?("/app/")
        slim_file_path.gsub!("/", "=").gsub!(".slim", "")

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
