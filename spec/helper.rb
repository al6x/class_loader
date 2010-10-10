require 'spec'
require 'fileutils'

def prepare_spec_data spec_file_name
  dir = File.expand_path(spec_file_name.sub(/\.rb$/, ''))
  original_data_dir = dir + "_data"
    
  FileUtils.rm_r dir if File.exist? dir
  FileUtils.cp_r original_data_dir, dir
    
  dir
end

def clean_spec_data spec_file_name
  dir = spec_file_name.sub(/\.rb$/, '')
  FileUtils.rm_r dir if File.exist? dir
end

def remove_constants *args
  args = args.first if args.size == 1 and args.first.is_a?(Array)
  args.each{|c| Object.send :remove_const, c if Object.const_defined? c}       
end