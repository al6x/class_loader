require "rspec_ext"
require "class_loader"

describe ClassLoader::FileSystemAdapter do  
  with_tmp_spec_dir
  
  before do
    @fs_adapter = ClassLoader::FileSystemAdapter.new(ClassLoader::CamelCaseTranslator)    
    
    # Actually we are testing both ChainedAdapter and FileSystemAdapter
    @adapter = ClassLoader::ChainedAdapter.new
    @adapter.adapters << @fs_adapter
    
    @adapter.add_path "#{spec_dir}/common"    
  end
  
  def write_file path, klass
    File.open("#{spec_dir}/#{path}", 'w'){|f| f.write "class #{klass}; end"}
  end
  
  it "exist?" do
    @adapter.exist?("SomeNamespace").should be_true
    @adapter.exist?("SomeNamespace::SomeClass").should be_true    
    @adapter.exist?("SomeNamespace::NonExistingClass").should be_false
  end
  
  it "should works with multiple class paths" do
    @adapter.add_path "#{spec_dir}/multiple_class_paths/path_a"
    @adapter.add_path "#{spec_dir}/multiple_class_paths/path_b"
      
    @adapter.exist?("ClassInPathA").should be_true
    @adapter.exist?("ClassInPathB").should be_true
  end
  
  it "read" do
    @adapter.read("SomeNamespace::SomeClass").should == "class SomeClass; end" 
  end
  
  it "to_file_path" do
    @adapter.to_file_path("NonExistingClass").should be_nil
    @adapter.to_file_path("SomeNamespace::SomeClass").should =~ /SomeNamespace\/SomeClass/
  end
  
  it "to_class_name" do
    @adapter.to_class_name("#{spec_dir}/non_existing_path").should be_nil
    @adapter.to_class_name("#{spec_dir}/common/SomeNamespace").should == "SomeNamespace"
    @adapter.to_class_name("#{spec_dir}/common/SomeNamespace/SomeClass").should == "SomeNamespace::SomeClass"
  end
  
  it "shouldn't add path twice" do
    @adapter.clear
    @adapter.add_path "#{spec_dir}/common"
    @adapter.add_path "#{spec_dir}/common"
    @fs_adapter.instance_variable_get("@paths").size.should == 1
  end
  
  describe "file watching" do      
    def changed_classes
      changed = []
      @adapter.each_changed_class{|c| changed << c}
      changed
    end
    
    it "each_changed_class shouldn't affect paths not specified for watching" do
      @adapter.add_path "#{spec_dir}/search_only_watched", false
      changed_classes.should == []        
      
      sleep(1) && write_file("watching/SomeClass.rb", "SomeClass")
      changed_classes.should == []
    end
      
    it "each_changed_class" do
      @adapter.add_path "#{spec_dir}/watching", true
      
      changed_classes.should == []        
    
      sleep(1) && write_file("watching/SomeClass.rb", "SomeClass")      
      changed_classes.should == ["SomeClass"]
    
      sleep(1) && write_file("watching/SomeClass.rb", "SomeClass")
      changed_classes.should == ["SomeClass"]
    end
  end
  
  describe "Underscored shouldn't mess with CamelCase" do
    before do
      @camel_case_adapter = ClassLoader::FileSystemAdapter.new(ClassLoader::CamelCaseTranslator)      
      @camel_case_adapter.add_path "#{spec_dir}/shouldnt_mess", true
      @camel_case_file_path = "#{spec_dir}/shouldnt_mess/CamelCaseClass.rb"
      
      @underscored_adapter = ClassLoader::FileSystemAdapter.new(ClassLoader::UnderscoredTranslator)  
      @underscored_adapter.add_path "#{spec_dir}/shouldnt_mess", true
      @underscored_file_path = "#{spec_dir}/shouldnt_mess/underscored_class.rb"
    end
    
    
    it "should watch only files understable by it's translator (CamelCase shouldn't load Underscored)" do      
      watched = []
      @camel_case_adapter.each_watched_file{|file_path, relative_name| watched << relative_name}
      watched.should == ["CamelCaseClass.rb"]
            
      watched = []
      @underscored_adapter.each_watched_file{|file_path, relative_name| watched << relative_name}
      watched.should == ["underscored_class.rb"]
    end
    
    it "CamelCase to_class_name shouldn't translate Underscored" do
      @camel_case_adapter.to_class_name(@camel_case_file_path.sub(/\.rb$/, '')).should == "CamelCaseClass"
      @underscored_adapter.to_class_name(@underscored_file_path.sub(/\.rb$/, '')).should == "UnderscoredClass"
    end
  end
end