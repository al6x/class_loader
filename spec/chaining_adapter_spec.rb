  it "ResourceProvider Chaining" do                     
    VResource.class_get("ChainTest").should == %{\
class ChainTest
# "ProviderB"
end}
    VResource.resource_get(ChainTest, "resource").should == "ProviderB"    
  end
