module ClassLoader
  class CamelCaseTranslator
    def self.to_class_name file_path
      file_path.sub(/^\//, '').gsub('/', '::')
    end
    
    def self.to_file_path class_name
      class_name.sub(/^::/, '').gsub('::', '/')
    end
    
    def self.is_it_class? file_name
      file_name !~ /_/
    end
  end
end