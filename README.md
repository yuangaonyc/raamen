# Raamen

[Raamen](http://rubygems.org/gems/raamen) is a Rack and SQLite based MVC web framework. It contains modules to provide basic and necessary features of web app components as well as helpful Rack middleware, cookie manipulation, and CLI to make the development process faster and easier.

#### contents
- SQLObject
- ControllerBase
- Routing
- Cookies
- Middleware
- Command Line Interface

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'raamen'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install raamen

## Usage

### SQLObject

```ruby
class Cat < Raamen::SQLObject
  belongs_to :owner,
    class_name: 'Human',
    foreign_key: :owner_id

  self.finalize!
end
```

### ControllerBase

```ruby
class CatsController < Raamen::ControllerBase
  def index
    @cats = Cat.all
    render :index
  end

  def new
    @cat = Cat.new
    render :new
  end

  def create
    cat = Cat.new(cat_params)
    cat.save
    redirect_to '/cats'
  end

  private

  def cat_params
    params['cat']
  end
end

```

### Routing

```ruby
router = Raamen::Router.new
router.draw do
  get Regexp.new("^/cats$"), CatsController, :index
  get Regexp.new("^/cats/new$"), CatsController, :new
  post Regexp.new("^/cats$"), CatsController, :create
end
```

### Cookies

```ruby
class MyController < ControllerBase
  def go
    session["count"] ||= 0
    session["count"] += 1
    render :counting_show
  end
end

```

```ruby
class DogsController < ControllerBase
  def create
    @dog = Dog.new(params["dog"])
    if @dog.save
      flash[:notice] = "Saved dog successfully"
      redirect_to "/dogs"
    else
      flash.now[:errors] = @dog.errors
      render :new
    end
  end
end
```

### Middleware

```ruby
app = Rack::Builder.new do
  use Raamen::ShowExceptions
  use Raamen::Static
  run app
end.to_app

```

### Command Line Interface

To start a new project:

```
$ raamen n/new cats
```

To generate a new component:

```
$ raamen g/generate controller CatsController
```

To start server:

```
$ raamen s/start
```

To start console:

```
$ raamen c/console
```

## Implementation

#### SQLObject modules:

```ruby
module Associatable
  def belongs_to(name, options = {})
    self.assoc_options[name] = BelongsToOptions.new(name, options)

    define_method(name) do
      options = self.class.assoc_options[name]
      key_val = self.send(options.foreign_key)
      options.model_class.where(options.primary_key => key_val).first
    end
  end

  def has_many(name, options = {})
    self.assoc_options[name] = HasManyOptions.new(name, self.name, options)

    define_method(name) do
      options = self.class.assoc_options[name]
      key_val = self.send(options.primary_key)
      options.model_class.where(options.foreign_key => key_val)
    end
  end
end
```

```ruby
module Searchable
  def where(params)
    where_line = params.keys.map do |col|
      "#{col}= ?"
    end.join(" AND ")

    parse_all(DBConnection.execute(<<-SQL, *params.values))
      SELECT
        *
      FROM
        #{self.table_name}
      where
        #{where_line}
    SQL
  end
end
```

#### Template rendering:

```ruby
def render_content(content, content_type)
  raise "double render" if already_built_response?
  self.res["Content-Type"] = content_type
  self.res.write(content)
  self.session.store_session(res)
  self.flash.store_flash(res)
  self.already_built_response = true
end

def render(template_name)
  template_path = File.join(
    Dir.pwd,
    "app",
    "views",
    "#{self.class.name.underscore}",
    "#{template_name}.html.erb"
    )
  template_content = File.read(template_path)
  render_content(ERB.new(template_content).result(binding), "text/html")
end
```

#### Redirecting:

```ruby
def redirect_to(url)
  raise "double render" if already_built_response?
  self.res["location"] = url
  self.res.status = 302
  self.session.store_session(res)
  self.flash.store_flash(res)
  self.already_built_response = true
end
```

#### Cross-Site Request Forgery protection:

```ruby
def form_authenticity_token
  self.res.set_cookie(
    "authenticity_token",
    {path: "/", value: self.authenticity_token}
  )
  self.authenticity_token
end

def self.protect_from_forgery
  @@protect_from_forgery = true
end

private

def generate_authenticity_token
  SecureRandom.urlsafe_base64(16)
end

def check_authenticity_token
  cookie = self.req.cookies["authenticity_token"]
  unless cookie && cookie == params["authenticity_token"]
    raise "Invalid authenticity token"
  end
end
```

#### Adding new routes:

```ruby
def add_route(pattern, method, controller_class, action_name)
  self.routes.push(Route.new(pattern, method, controller_class, action_name))
end

def draw(&proc)
  self.instance_eval(&proc)
end

[:get, :post, :put, :delete].each do |http_method|
  define_method(http_method) do |pattern, controller_class, action_name|
    add_route(pattern, http_method, controller_class, action_name)
  end
end
```

#### Flash cookies:

```ruby
class Flash
  attr_reader :flash, :now

  def initialize(req)
    flash = req.cookies["_rails_lite_app_flash"]
    @now = flash ? Now.new(JSON.parse(flash)) : Now.new({})
    @flash = {}
  end

  def [](key)
    self.now[key.to_sym] || self.flash[key.to_sym]
  end

  def []=(key, val)
    self.flash[key.to_sym] = val
  end

  def store_flash(res)
    res.set_cookie("_rails_lite_app_flash", {path: "/", value: self.flash.to_json})
  end
end
```

#### Sesssion Cookies:

```ruby
class Session
  attr_reader :cookies

  def initialize(req)
    cookies = req.cookies["_rails_lite_app"]
    cookies = Hash[JSON.parse(cookies).map{ |k,v| [k.to_sym, v] }] if cookies
    @cookies = cookies || {}
  end

  def [](key)
    self.cookies[key.to_sym]
  end

  def []=(key, val)
    self.cookies[key.to_sym] = val
  end

  def store_session(res)
    res.set_cookie("_rails_lite_app", {path: "/", value: self.cookies.to_json})
  end
end
```

#### Show exceptions middleware:

```ruby
class ShowExceptions
  attr_reader :app

  def initialize(app)
    @app = app
  end

  def call(env)
    begin
      self.app.call(env)
    rescue Exception => e
      render_exception(e)
    end
  end
end
```

#### Static assets middleware:

```ruby
class Static
  attr_reader :app, :root, :file_server

  def initialize(app)
    @app = app
    @root = :public
    @file_server = FileServer.new(self.root)
  end

  def call(env)
    req = Rack::Request.new(env)
    path = req.path

    if path.include?("/#{self.root}")
      res = self.file_server.call(env)
    else
      res = self.app.call(env)
    end

    res
  end
end

```


## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/raamen. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
