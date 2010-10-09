require "#{File.expand_path(File.dirname(__FILE__))}/helper"
require "class_loader/file_system_adapter"

describe ClassLoader::FileSystemAdapter do  
  before :all do
    @dir = __FILE__.sub(/\.rb$/, '')
  end
  
  before :each do    
    @adapter = ClassLoader::FileSystemAdapter.new(@dir)

    # VResource.add_resource_provider @provider
    # 
    # VResource.add_resource_provider VResource::FileSystemProvider.new("#{@dir}/provider_chaining/provider_a_dir")
    # VResource.add_resource_provider VResource::FileSystemProvider.new("#{@dir}/provider_chaining/provider_b_dir")
    # 
    # module ::NonExistingNamespace; end
    # module ::SomeNamespace; end    
    # module ::ResourceTest
    #   class Test; end
    # end
    # module ::ChangedClass; end
    # class ::ChainTest; end
    # class ::ResourceExtension; end
  end
  
  after :all do
    # remove_constants %w(
    #   SomeNamespace
    # )
    # FileUtils.rm_r @dir if File.exist? @dir
    # [:SomeNamespace, :NonExistingNamespace, :ResourceTest, :ChangedClass, :ChainTest, :ResourceExtension].
    #   each{|c| Object.send :remove_const, c}
  end
  
  describe "camel case" do
    before :each do
      @adapter.paths << "#{@dir}/camel_case/common"
    end
    
    it "exist?" do
      @adapter.exists?("SomeNamespace").should be_true
      @adapter.exists?("SomeNamespace::SomeClass").should be_true    
      @adapter.exists?("SomeNamespace::NonExistingClass").should be_false
    end

    it "should works with multiple class paths" do
      @adapter.paths = [
        "#{@dir}/multiple_class_paths/path_a", 
        "#{@dir}/multiple_class_paths/path_b"
      ]

      @adapter.exists?("ClassInPathA").should be_true
      @adapter.exists?("ClassInPathB").should be_true
    end

    it "read" do
      @adapter.read("SomeNamespace::SomeClass").should == "class SomeClass; end" 
    end

    it "translate_class_name_to_virtual_file_name" do
      lambda{@adapter.translate_class_name_to_virtual_file_name("NonExistingClass")}.should raise_error(/doesn't exist!/)
      @adapter.translate_class_name_to_virtual_file_name("SomeNamespace::SomeNamespace").should =~ /SomeNamespace\/SomeClass/
    end

    it "watching" do
      # Observer
      # class CustomObserver 
      #   attr_reader :classes, :resources
      # 
      #   def initialize
      #     @classes, @resources = [], []
      #   end
      # 
      #   def update_resource type, klass, resource
      #     if type == :class
      #       @classes << klass
      #     else
      #       @classes << klass
      #       @resources << resource
      #     end 
      #   end
      # end
      # 
      # obs = CustomObserver.new

      @adapter.paths << "#{@dir}/camel_case/watching"
      
      changed = []
      @adapter.add_observer do |klass_name|
        changed << klass_name
      end

      @provider.reloader.reset
      @provider.reloader.check
      changed.size.should == 0
      
      sleep 1 # it willn't works if you set smaller amount of time, somehow OS doesn't notice it.

      File.write("#{@dir}/ChangedClass.rb", "class ChangedClass; end")
      File.write("#{@dir}/ChangedClass.txt", "fsd")
      File.write("#{@dir}/ChangedClass.res/Text.txt", "")

      @provider.reloader.check

      # Assertions
      obs.classes.size.should == 3
      obs.classes.all?{|k| k == ChangedClass}.should be_true

      obs.resources.size.should == 2
      obs.resources.should include("txt")
      obs.resources.should include("Text.txt")
    end    
  end
  
  describe "underscored" do
  end
end