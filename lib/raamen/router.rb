module Raamen
  class Route
    attr_reader :pattern, :http_method, :controller_class, :action_name

    def initialize(pattern, http_method, controller_class, action_name)
      @pattern = pattern
      @http_method = http_method
      @controller_class = controller_class
      @action_name = action_name
    end

    def matches?(req)
      req.path =~ self.pattern &&
      req.request_method == self.http_method.to_s.upcase
    end

    def run(req, res)
      match_data = self.pattern.match(req.path)
      route_params = Hash[match_data.names.zip(match_data.captures)]
      self.controller_class.new(req, res, route_params)
        .invoke_action(self.action_name)
    end
  end

  class Router
    attr_reader :routes

    def initialize
      @routes = []
    end

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

    def match(req)
      self.routes.each do |route|
        return route if route.matches?(req)
      end
      nil
    end

    def run(req, res)
      matching_route = match(req)
      unless matching_route
        res.status = 404
        return
      end
      matching_route.run(req, res)
    end
  end
end
