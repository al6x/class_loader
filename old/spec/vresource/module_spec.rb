require "#{File.dirname __FILE__}/helper"
require "vresource/class_loader"
require "vresource/module"

describe "VResource, Module" do  
  
  before :all do
    @original_dir = "#{File.dirname(__FILE__)}/module_spec_data"
    @dir = "#{File.dirname(__FILE__)}/module_spec"
    
    FileUtils.rm_r @dir if File.exist? @dir
    FileUtils.cp_r @original_dir, @dir
    
    @provider = VResource::FileSystemProvider.new(@dir)
    VResource.add_resource_provider @provider
    VResource.hook!
  end
  
  after :all do
    VResource.unhook!
    FileUtils.rm_r @dir if File.exist? @dir
    [:NS1, :NS2].each{|c| Object.send :remove_const, c if Object.const_defined? c}
  end

  it "resources" do
    ::NS1::B.clear_cache_method
    ::NS1::B2.clear_cache_method
    
    ::NS1::B["data"].should == "A.data"
    ::NS1::B2["data"].should == "NS1.data"
  end
  
  it "resources, should aslo inherit resources from included modules" do
    ::NS2::B.clear_cache_method    
    
    ::NS2::B["data"].should == "M.data"
  end

end
