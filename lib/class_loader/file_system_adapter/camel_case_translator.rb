module ClassLoader
  class CamelCaseTranslator
    def self.to_class_name file_path
      file_path.sub(/^\//, '').gsub('/', '::')
    end
    
    def self.to_file_path class_name
      class_name.sub(/^::/, '').gsub('::', '/')
    end
  end
end