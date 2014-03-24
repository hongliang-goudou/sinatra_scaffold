get "/test" do
  # cookie设置：
  # response.set_cookie(:test, value: "test123-value", path: "/", max_age: "3600")
  #
  # session存取：
  # session[:test_session]
  # session.delete(:test_session)
  #
  # flash设置：
  # flash.now[:notice] = "Notice! This is flash message!"
  #
  # HTML清洗：
  # html = '<b><a href="http://foo.com/">foo</a></b><img src="http://foo.com/bar.jpg">'
  # ap Sanitize.clean(html)
  #
  # 输出JSON：
  # ap json foo: "bar", bar: %w(hello world test)

  slim :test
end
