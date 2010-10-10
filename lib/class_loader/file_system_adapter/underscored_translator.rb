module ClassLoader
  class UnderscoredTranslator
    def self.to_class_name file_path
      file_path.sub(/^\//, '').camelize
    end
    
    def self.to_file_path class_name
      class_name.sub(/^::/, '').underscore
    end
  end
end