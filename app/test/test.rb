class App < Sinatra::Base
  get "/test" do
    slim :test
  end
end
