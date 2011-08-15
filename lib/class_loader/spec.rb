require 'rspec_ext'

rspec do
  def self.with_autoload_path *paths
    before(:all){paths.each{|path| ClassLoader.autoload_path path}}
    after(:all){paths.each{|path| ClassLoader.delete_path path}}
  end
  
  def with_autoload_path *paths, &b
    begin
      paths.each{|path| ClassLoader.autoload_path path}
      b.call
    ensure
      paths.each{|path| ClassLoader.delete_path path}
    end
  end
end