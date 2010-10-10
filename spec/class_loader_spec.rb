require "#{File.expand_path(File.dirname(__FILE__))}/helper"
require "class_loader"

describe ClassLoader do  
  before :all do
    @dir = prepare_spec_data __FILE__
  end
  
  after :all do
    clean_spec_data __FILE__

    remove_constants %w(
      BasicSpec
      OnlyOnceSpec
      NamespaceTypeResolving NamespaceIsAlreadyDefinedAsClass
      InvalidInfinityLoopClassName
      AnonymousSpec
      AnotherNamespace
      ClassReloadingSpec
      UnloadOldClass
      PreloadingSpec
      UnderscoredNamespace
    )        
  end
  
  after :each do
    ClassLoader.clear
  end
  
  it "should load classes from class path" do
    autoload_dir "#{@dir}/basic"
    
    BasicSpec
    BasicSpec::SomeNamespace::SomeClass
  end
    
  it "should load classes only once" do
    autoload_dir "#{@dir}/only_once"
    
    check = mock
    check.should_receive(:loaded).once
    ClassLoader.add_observer do |klass|
      klass.name.should == "OnlyOnceSpec"
      check.loaded
    end
    
    OnlyOnceSpec
    OnlyOnceSpec
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
    lambda{
      AnotherNamespace::NamespaceB
    }.should raise_error(/Class '.+' is not defined in the '.+' Namespace!/)
  end
  
  describe "reloading" do  
    it "should reload class files" do
      spec_dir = "#{@dir}/class_reloading"
      fname = "#{spec_dir}/ClassReloadingSpec.rb"
      autoload_dir spec_dir

      code = <<-RUBY
class ClassReloadingSpec
  def self.check; :value end
end
RUBY
    
      File.open(fname, 'w'){|f| f.write code}
    
      ClassReloadingSpec.check.should == :value

      code = <<-RUBY
class ClassReloadingSpec
  def self.check; :another_value end
end
RUBY

      File.open(fname, 'w'){|f| f.write code}
    
      ClassLoader.reload_class(ClassReloadingSpec.name)
      ClassReloadingSpec.check.should == :another_value
    end
  
    it "should unload old classes before reloading" do
      autoload_dir "#{@dir}/unload_old_class"
      UnloadOldClass.instance_variable_set "@value", :value
      ClassLoader.reload_class(UnloadOldClass.name)
      UnloadOldClass.instance_variable_get("@value").should == nil
    end
  end
  
  it "should be able to preload all classes in production" do
    autoload_dir "#{@dir}/preloading"
    Object.const_defined?(:PreloadingSpec).should be_false    
    ClassLoader.preload!
    Object.const_defined?(:PreloadingSpec).should be_true
  end  
  
  it "underscored smoke test" do
    autoload_dir "#{@dir}/underscored"
    
    UnderscoredNamespace::UnderscoredClass
  end
end