require 'json'

module Raamen
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

  class Now
    attr_reader :now

    def initialize(now)
      @now = Hash[now.map{ |k,v| [k.to_sym, v] }]
    end

    def [](key)
      self.now[key.to_sym]
    end

    def []=(key, val)
      self.now[key.to_sym] = val
    end
  end
end
