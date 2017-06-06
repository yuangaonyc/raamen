module Raamen
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
end
