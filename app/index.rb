class App < Sinatra::Base
  get "/" do
    "Hello, Sinatra! development? #{settings.development?}"
  end
end
