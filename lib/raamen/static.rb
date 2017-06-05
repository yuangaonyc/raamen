module Raamen
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

  class FileServer
    MIME_TYPES = {
      ".txt" => "text/plain",
      ".jpg" => "image/jpeg",
      ".zip" => "application/zip"
    }

    def initialize(root)
      @root = root
    end

    def call(env)
      req = Rack::Request.new(env)
      res = Rack::Response.new
      file_path = File.join(
        File.dirname(__FILE__),
        "..",
        req.path
      )

      if File.exist?(file_path)
        extension = File.extname(file_path)
        content_type = MIME_TYPES[extension]
        file_content = File.read(file_path)
        res["Content-Type"] = content_type
        res.write(file_content)
      else
        res.status = 404
        res.write("File not found")
      end

      res
    end
  end
end
