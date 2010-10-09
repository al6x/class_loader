require 'ruby_ext'

%w{
  file_system_provider
  file_system_reloader

  vresource
  resource_extensions
  class_loader

  module
}.each{|f| require "vresource/#{f}"}

def autoload_dir *args
  VResource.autoload_dir *args
end