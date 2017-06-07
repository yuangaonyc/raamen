# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'raamen/version'

Gem::Specification.new do |spec|
  spec.name          = "raamen"
  spec.version       = Raamen::VERSION
  spec.authors       = ["Yuan Gao"]
  spec.email         = ["yuangaonyc@gmail.com"]

  spec.summary       = "A rack based web framework"
  spec.description   = "Raamen is a Rack and SQLite based MVC web framework. It contains modules to provide basic and necessary features of web app components as well as helpful Rack middleware, cookie manipulation, and CLI to make the development process faster and easier."
  spec.homepage      = "https://github.com/yuangaonyc/raamen"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  # if spec.respond_to?(:metadata)
  #   spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  # else
  #   raise "RubyGems 2.0 or newer is required to protect against " \
  #     "public gem pushes."
  # end

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end

  spec.executables   = ["raamen"]
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.14"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
