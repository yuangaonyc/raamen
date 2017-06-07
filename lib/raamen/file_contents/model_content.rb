class FileContent
  def self.model_content(name)
"class #{name} < Raamen::SQLObject
  self.finalize!
  
end"
  end
end
