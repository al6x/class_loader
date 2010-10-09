require "#{File.expand_path(File.dirname(__FILE__))}/helper"
require "class_loader"

describe ClassLoader do  
  def autoload_dir *args
    ClassLoader.autoload_dir *args
  end
  
  before :all do
    @dir = __FILE__.sub(/\.rb$/, '')

    # @provider = VResource::FileSystemProvider.new(@dir)
    # VResource.add_resource_provider @provider
    # VResource.hook!
  end
  
  after :all do
    # VResource.unhook!
    remove_constants %w(
      BasicSpec
      OnlyOnceSpec
      NamespaceTypeResolving NamespaceIsAlreadyDefinedAsClass
      InvalidInfinityLoopClassName
      AnonymousSpec
      AnotherNamespace
      ClassReloadingSpec
    )    
  end
  
  after :each do
    ClassLoader.autoload_dir = []
    ClassLoader.observers = []
    ClassLoader.error_on_defined_constant = false
  end
  
  it "should load classes from class path" do
    autoload_dir "#{@dir}/basic"
    BasicSpec
    BasicSpec::SomeNamespace::SomeClass
  end
    
  it "should load classes only once" do
    # class CustomObserver
    #   attr_reader :list
    #   def initialize
    #     @list = []
    #   end
    #   
    #   def update_class klass
    #     @list << klass
    #   end
    # end
    # obs = CustomObserver.new
    # ClassLoader.add_observer obs
    
    autoload_dir "#{@dir}/only_once"
    
    check = mock
    check.should_receive(:loaded).once
    ClassLoader.add_observer do |klass|
      klass.name.should == "OnlyOnceSpec"
      check.loaded
    end
    
    OnlyOnceSpec
    OnlyOnceSpec


    # LoadCount
    # LoadCount
    # ClassLoader.delete_observers
    
    # obs.list.inject(0){|count, klass| klass == ::LoadCount ? count + 1 : count}.should == 1
  end
  
  it "should resolve is namespace a class or module" do
    autoload_dir "#{@dir}/namespace_type_resolving"
    
    NamespaceTypeResolving.class.should == Class
    NamespaceTypeResolving::SomeClass
    
    class NamespaceIsAlreadyDefinedAsClass; end    
    NamespaceIsAlreadyDefinedAsClass::SomeClass
  end
  
  it "should recognize infinity loop" do
    autoload_dir "#{@dir}/infinity_loop"
    
    lambda{InfinityLoop}.should raise_error(/Class Name .+ doesn't correspond to File Name/)
  end
  
  it "should correctly works inside of anonymous class" do
    autoload_dir "#{@dir}/anonymous_class"
    
    module ::AnonymousSpec
      class << self
        def anonymous
          ClassInsideOfAnonymousClass
        end
      end
    end
    
    AnonymousSpec.anonymous
  end
  
  it "should raise exception if class defined in another namespace" do
    autoload_dir "#{@dir}/another_namespace"
    
    AnotherNamespace::NamespaceA
    ClassLoader.error_on_defined_constant = true
    lambda{::AnotherNamespace::NamespaceB}.should raise_error(/Class '.+' is not defined in the '.+' Namespace!/)
  end

  it "should reload class files" do
    spec_dir = "#{@dir}/class_reloading_spec"
    fname = "#{spec_dir}/ClassReloadingSpec.rb"
    autoload_dir spec_dir

    code = <<-RUBY
class ClassReloadingSpec
  def self.check; :value end
end
RUBY
    
    File.open(fname){|f| f.write code}
    
    ClassReloadingSpec.check.should == :value

    code = <<-RUBY
class ClassReloadingSpec
  def self.check; :another_value end
end
RUBY

    File.open(fname){|f| f.write code}
    
    ClassLoader.reload_class(ClassReloading.name)
    ClassReloadingSpec.check.should == :another_value
  end
  
  it "add check that it actually unload old classes (remove old class constant before reloading)"
  
  it "should be able to preload all classes in production"
  
  it "should watch class files for changes (if specified as autoload_dir(dir, true))"
end