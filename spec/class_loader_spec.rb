require 'rspec_ext'
require "class_loader"

describe 'Autoloading classes' do
  with_tmp_spec_dir

  after do
    remove_constants :SomeNamespace, :SomeClass, :AnotherClass, :Tmp

    ClassLoader.loaded_classes.clear
    ClassLoader.watcher.stop
  end

  it "basics" do
    with_load_path "#{spec_dir}/basics" do
      SomeClass.name.should == 'SomeClass'
      SomeClass.class.should == Class

      SomeNamespace::SomeClass.name.should == 'SomeNamespace::SomeClass'
      SomeNamespace.class.should == Module

      SomeNamespace::AnotherClass
    end
  end

  it "should load classes only once" do
    begin
      Tmp = []
      ClassLoader.class_eval do
        class << self
          alias_method :load_without_test, :load
          def load_with_test namespace, const
            Tmp << const
            load_without_test namespace, const
          end
          alias_method :load, :load_with_test
        end
      end

      with_load_path "#{spec_dir}/only_once" do
        SomeClass
        SomeClass
      end

      Tmp.should == [:SomeClass]
    ensure
      ClassLoader.class_eval do
        class << self
          alias_method :load, :load_without_test
        end
      end
    end
  end

  it "should resolve namespace" do
    with_load_path "#{spec_dir}/namespace_resolving" do
      SomeNamespace

      SomeNamespace.class.should == Module
      SomeNamespace::SomeClass
    end
  end

  it "should recognize infinity loop" do
    with_load_path "#{spec_dir}/infinity_loop" do
      -> {SomeClass}.should raise_error(/class name 'SomeClass' doesn't correspond to file name 'some_class'/)
    end
  end

  it "should correctly works inside of anonymous class" do
    with_load_path "#{spec_dir}/anonymous_class" do
      module SomeNamespace
        class << self
          def anonymous
            SomeClass
          end
        end
      end

      SomeNamespace.anonymous
    end
  end

  it "should raise exception if class defined in another namespace" do
    with_load_path "#{spec_dir}/another_namespace" do
      SomeNamespace::NamespaceA
      -> {SomeNamespace::NamespaceB}.should raise_error(/something wrong with/)
    end
  end

  it "should reload class files" do
    with_load_path "#{spec_dir}/reloading" do
      watcher = ClassLoader.watcher
      watcher.paths << "#{spec_dir}/reloading"

      # Watcher should not load classes by itself.
      watcher.check
      Object.const_defined?(:SomeClass).should be_false

      # Autoloading class.
      SomeClass.version.should == 1

      # Writing new version of file.
      code = <<-RUBY
class SomeClass
def self.version; 2 end
end
RUBY

      class_path = "#{spec_dir}/reloading/some_class.rb"
      File.open(class_path, 'w'){|f| f.write code}

      # File system doesn't notice small changes in file update date, so
      # we stubbing it.
      updated_at = File.mtime class_path
      File.stub!(:mtime).and_return(updated_at + 1)

      # Should reload class.
      watcher.stub! :warn
      ClassLoader.watcher.check
      SomeClass.version.should == 2
    end
  end

  it "should be able to preload all classes in production" do
    with_load_path "#{spec_dir}/preloading" do
      Object.const_defined?(:SomeClass).should be_false
      Object.const_defined?(:SomeNamespace).should be_false

      ClassLoader.preload "#{spec_dir}/preloading"

      Object.const_defined?(:SomeClass).should be_true
      Object.const_defined?(:SomeNamespace).should be_true
      SomeNamespace.const_defined?(:AnotherClass).should be_true
    end
  end
end