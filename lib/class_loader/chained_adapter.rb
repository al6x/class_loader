class ClassLoader::ChainedAdapter
  attr_accessor :adapters

  def initialize
    @adapters = []
  end
  
  %w(
    exist?
    read
    to_file_path
    to_class_name
  ).each do |method|
    define_method method do |*args|
      catch :found do
        adapters.each do |a|
          value = a.send method, *args
          throw :found, value if value
        end
        nil
      end
    end
  end
  
  def each_changed_class &block      
    adapters.each{|a| a.each_changed_class &block}
  end
  
  def each_class &block
    adapters.each{|a| a.each_class &block}
  end
  
  def clear
    adapters.each{|a| a.clear}
  end
  
  def add_path *args
    adapters.each do |a|
      a.add_path *args if a.respond_to? :add_path
    end
  end
  
  def delete_path *args
    adapters.each do |a|
      a.add_path *args if a.respond_to? :delete_path
    end
  end
end