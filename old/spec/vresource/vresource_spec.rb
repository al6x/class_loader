require "#{File.dirname __FILE__}/helper"
require "vresource/file_system_reloader"
require "vresource/resource_extensions"

describe "VResource" do
  
  before :all do
    @original_dir = "#{File.dirname(__FILE__)}/vresource_spec_data"
    @dir = "#{File.dirname(__FILE__)}/vresource_spec"
    
    FileUtils.rm_r @dir if File.exist? @dir
    FileUtils.cp_r @original_dir, @dir
    
    @provider = VResource::FileSystemProvider.new(@dir)
    VResource.add_resource_provider @provider

    VResource.add_resource_provider VResource::FileSystemProvider.new("#{@dir}/provider_chaining/provider_a_dir")
    VResource.add_resource_provider VResource::FileSystemProvider.new("#{@dir}/provider_chaining/provider_b_dir")
    
    module ::NonExistingNamespace; end
    module ::SomeNamespace; end    
    module ::ResourceTest
      class Test; end
    end
    module ::ChangedClass; end
    class ::ChainTest; end
    class ::ResourceExtension; end
  end
  
  after :all do
    FileUtils.rm_r @dir if File.exist? @dir
    [:SomeNamespace, :NonExistingNamespace, :ResourceTest, :ChangedClass, :ChainTest, :ResourceExtension].
      each{|c| Object.send :remove_const, c}
  end
  
  it "shouldn't write class if it's namespace doesn't exist" do    
    lambda{VResource.class_set("NonExistingNamespace::SomeClass", "class SomeClass; end", @dir)}.
      should raise_error(/doesn't exist/)
  end
  
  it "class get, set, exist, delete" do
    VResource.class_exist?("SomeNamespace::SomeClass").should be_false
    VResource.class_set("SomeNamespace::SomeClass", "class SomeClass; end", @dir)   
    VResource.class_exist?("SomeNamespace::SomeClass").should be_true
    
    VResource.class_get("SomeNamespace::SomeClass").should == "class SomeClass; end"
    
    VResource.class_delete("SomeNamespace::SomeClass")
    VResource.class_exist?("SomeNamespace::SomeClass").should be_false      
  end
    
  it "namespace" do
    VResource.class_exist?("SomeNamespace").should be_true
  end
  
  it "resource get, set, delete, exist" do
    VResource.resource_get(ResourceTest::Test, "txt").should == "Test.txt"
    VResource.resource_get(ResourceTest::Test, "Data.txt").should == "Data.txt"
    
    VResource.resource_exist?(ResourceTest::Test, "txt").should be_true
    VResource.resource_exist?(ResourceTest::Test, "Data.txt").should be_true
    
    VResource.resource_delete(ResourceTest::Test, "txt")
    VResource.resource_delete(ResourceTest::Test, "Data.txt")
    VResource.resource_exist?(ResourceTest::Test, "txt").should be_false
    VResource.resource_exist?(ResourceTest::Test, "Data.txt").should be_false
    
    
    VResource.resource_set(ResourceTest::Test, "txt", "Test.txt")
    VResource.resource_set(ResourceTest::Test, "Data.txt", "Data.txt")
    VResource.resource_get(ResourceTest::Test, "txt").should == "Test.txt"
    VResource.resource_get(ResourceTest::Test, "Data.txt").should == "Data.txt"
  end
  
  it "Class to Path" do
    lambda{VResource.to_file_path("A::B::C")}.should raise_error(/doesn't exist!/)
    VResource.to_file_path("ResourceTest::Test").should =~ /ResourceTest\/Test/
  end
      
  it "ResourceProvider Chaining" do                     
    VResource.class_get("ChainTest").should == %{\
class ChainTest
# "ProviderB"
end}
    VResource.resource_get(ChainTest, "resource").should == "ProviderB"    
  end
    
  it "ResourceExtension" do
    lambda{VResource.resource_get ResourceExtension, "Data.yaml"}.should raise_error(/doesn't exist/)
    VResource.resource_set ResourceExtension, "Data.yaml", {:value => true}
    res = VResource.resource_get ResourceExtension, "Data.yaml"
    res.should == {:value => true}
  end        
  
  it "change listeners" do
    # Observer
    class CustomObserver 
      attr_reader :classes, :resources
      
      def initialize
        @classes, @resources = [], []
      end
      
      def update_resource type, klass, resource
        if type == :class
          @classes << klass
        else
          @classes << klass
          @resources << resource
        end 
      end
    end
    
    obs = CustomObserver.new
    VResource.add_observer obs
    
    # Check for updated files
    @provider.reloader.reset
    @provider.reloader.check
    obs.classes.size.should == 0
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