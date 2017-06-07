class FileContent
  def self.controller_content(name)
"class #{name} < Raamen::ControllerBase

end"
  end
end
