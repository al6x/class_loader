raise 'ruby 1.9.2 or higher required!' if RUBY_VERSION < '1.9.2'

%w(
  support
  file_system_adapter/camel_case_translator
  file_system_adapter/underscored_translator
  file_system_adapter  
  chained_adapter
  class_loader
).each{|f| require "class_loader/#{f}"}

def autoload_dir *args, &block
  ClassLoader.autoload_dir *args, &block
end 