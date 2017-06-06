module Raamen
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

    private

    def render_exception(e)
      template_path = File.join(
        File.dirname(__FILE__),
        "templates",
        "rescue.html.erb")
      template_content = File.read(template_path)
      content = ERB.new(template_content).result(binding)

      res = Rack::Response.new
      res.status = 500
      res["Content-Type"] = "text/html"
      res.write(content)
      res.finish
    end

    def stack_trace_top(e)
      e.backtrace[0].split(':')
    end

    def source_line_num(e)
      stack_trace_top(e)[1].to_i
    end

    def error_source_file(e)
      stack_trace_top(e)[0]
    end

    def extract_source(file)
      source_file = File.open(file, 'r')
      source_file.readlines
    end

    def format_source(source_lines, source_line_num)
      start = [0, source_line_num - 3].max
      lines = source_lines[start..(start + 5)]
      Hash[*(start + 1..(lines.count + start)).zip(lines).flatten]
    end

    def extract_formatted_source(e)
      source_file_name = error_source_file(e)
      source_line_num = source_line_num(e)
      source_lines = extract_source(source_file_name)
      format_source(source_lines, source_line_num)
    end
  end
end
