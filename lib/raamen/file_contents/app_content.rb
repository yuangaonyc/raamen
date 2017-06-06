class FileContent
  def self.app_content
"require 'raamen'
require 'rack'

router = Raamen::Router.new
router.draw do
  # Add routes here, example:
  # get Regexp.new(\"^/cats$\"), CatsController, :index
end

app = Proc.new do |env|
  req = Rack::Request.new(env)
  res = Rack::Response.new
  router.run(req, res)
  res.finish
end

app = Rack::Builder.new do
  use Raamen::ShowExceptions
  use Raamen::Static
  run app
end.to_app

Rack::Server.start(
 app: app,
 Port: 3000
)"
  end
end
