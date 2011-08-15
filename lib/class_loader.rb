raise 'ruby 1.9.2 or higher required!' if RUBY_VERSION < '1.9.2'

module ClassLoader
end

%w(
  support
  file_system_adapter/camel_case_translator
  file_system_adapter/underscored_translator
  file_system_adapter  
  chained_adapter
  class_loader
).each{|f| require "class_loader/#{f}"}

def autoload_path *args, &block
  ClassLoader.autoload_path *args, &block
end
def autoload_dir *a, &b
  warn 'ClassLoader: the :autoload_dir method is deprecated, please use :autoload_path'
  autoload_path *a, &b
end