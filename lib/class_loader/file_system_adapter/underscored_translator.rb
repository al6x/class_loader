module ClassLoader::UnderscoredTranslator
  def self.to_class_name normalized_file_name
    raise "internall error, invalid format for #{normalized_file_name}!" if normalized_file_name =~ /^\//
    normalized_file_name.camelize
  end

  def self.to_file_path class_name
    raise "internall error, invalid format for #{class_name}!" if class_name =~ /^::/
    class_name.underscore
  end

  def self.is_it_class? normalized_file_name
    raise "internall error, invalid format for #{normalized_file_name}!" if normalized_file_name =~ /^\//
    normalized_file_name[0..0] =~ /[a-z]/
  end
end