require 'rake'
require 'spec/rake/spectask'

Dir.chdir File.dirname(__FILE__)	

# Specs
task :default => :spec

Spec::Rake::SpecTask.new('spec') do |t|
	t.spec_files = FileList["spec/**/*_spec.rb"].select{|f| f !~ /\/_/}
  t.libs = ['lib'].collect{|f| "#{File.dirname __FILE__}/#{f}"}
  # t.spec_opts = ["--backtrace"]
end

# Gem
require 'rake/clean'
require 'rake/gempackagetask'
require 'fileutils'

spec = Gem::Specification.new do |s|
  s.name = "class-loader"
  s.version = "0.3.1" 
  s.summary = "Makes any directory looks like Ruby Gem"
  s.description = "Makes any directory looks like Ruby Gem"
  s.author = "Alexey Petrushin"
  # s.email = ""
  s.homepage = "http://github.com/alexeypetrushin/class-loader"
  
  s.platform = Gem::Platform::RUBY
  s.has_rdoc = true
  
  s.files = (['Rakefile', 'readme.md'] + Dir.glob("{lib,spec}/**/*"))
  
  s.require_paths = ["lib"]
end

PACKAGE_DIR = "#{File.expand_path File.dirname(__FILE__)}/build"

Rake::GemPackageTask.new(spec) do |p|
  package_dir = PACKAGE_DIR
# FileUtils.mkdir package_dir unless File.exist? package_dir  
  p.need_tar = true if RUBY_PLATFORM !~ /mswin/
  p.need_zip = true
  p.package_dir = package_dir
end

# CLEAN.include [ 'pkg', '*.gem']

task :push do
  dir = Dir.chdir PACKAGE_DIR do
    gem_file = Dir.glob("class-loader*.gem").first
    system "gem push #{gem_file}"
  end
end

task :clean do
  system "rm -r #{PACKAGE_DIR}"
end

task :release => [:gem, :push, :clean]