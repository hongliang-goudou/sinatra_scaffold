# 定义Rack::Csrf的helper，其实就是一些简单写法
helpers do
  def csrf_metatag
    Rack::Csrf.csrf_metatag(env)
  end

  def csrf_tag
    Rack::Csrf.csrf_tag(env)
  end

  def csrf_token
    Rack::Csrf.csrf_token(env)
  end

  def csrf_field
    Rack::Csrf.csrf_field
  end
end
