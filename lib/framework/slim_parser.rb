module Slim
  class Parser
    alias_method :parse_line_indicators_old, :parse_line_indicators unless method_defined?(:parse_line_indicators_old)

    def parse_line_indicators
      line = @line

      # 与我们自己重新覆写的slim_embedded_engine.rb配合，使下层代码得知当前slim文件名
      if line[/\A(javascript|css):\s*\Z/]
        result = parse_text_block
        result << [:static, options[:file]]
        @stacks.last << [:slim, :embedded, $1, result]
        @stacks.last << [:newline]
      else
        result = parse_line_indicators_old
      end

      result
    end
  end
end
