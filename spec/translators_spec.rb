require 'rspec_ext'
require 'class_loader/file_system_adapter/camel_case_translator'
require 'class_loader/file_system_adapter/underscored_translator'

describe "Translators" do
  describe "CamelCase" do
    before :all do
      @t = ClassLoader::CamelCaseTranslator
    end

    it "is_it_class?" do
      @t.is_it_class?("SomeClass.rb").should be_true
      @t.is_it_class?("SomeNamespace/SomeClass.rb").should be_true

      @t.is_it_class?("someclass.rb").should be_false
      @t.is_it_class?("some_class.rb").should be_false
      @t.is_it_class?("some_namespace/some_class.rb").should be_false
    end
  end

  describe "Underscored" do
    before :all do
      @t = ClassLoader::UnderscoredTranslator
    end

    it "is_it_class?" do
      @t.is_it_class?("SomeClass.rb").should be_false
      @t.is_it_class?("SomeNamespace/SomeClass.rb").should be_false

      @t.is_it_class?("someclass.rb").should be_true
      @t.is_it_class?("some_class.rb").should be_true
      @t.is_it_class?("some_namespace/some_class.rb").should be_true
    end
  end
end