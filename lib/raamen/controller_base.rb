require 'active_support'
require 'active_support/core_ext'
require 'erb'
require 'json'
require_relative 'session'
require_relative 'flash'

module Raamen
  class ControllerBase
    attr_reader :req, :res, :params, :session, :flash
    attr_accessor :already_built_response, :authenticity_token

    def initialize(req, res, route_params = {})
      @req = req
      @res = res
      @params = route_params.merge(req.params)
      @session = Session.new(req)
      @flash = Flash.new(req)
      @already_built_response = false
      @authenticity_token = generate_authenticity_token
      @@protect_from_forgery ||= false
    end

    def already_built_response?
      self.already_built_response
    end

    def redirect_to(url)
      raise "double render" if already_built_response?
      self.res["location"] = url
      self.res.status = 302
      self.session.store_session(res)
      self.flash.store_flash(res)
      self.already_built_response = true
    end

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
        "views",
        "#{self.class.name.underscore}",
        "#{template_name}.html.erb"
        )
      template_content = File.read(template_path)
      render_content(ERB.new(template_content).result(binding), "text/html")
    end

    def invoke_action(name)
      if @@protect_from_forgery && self.req.request_method != "GET"
        check_authenticity_token
      end
      self.send(name)
      render(name) unless already_built_response?
    end

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
  end
end
