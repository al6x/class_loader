class Module
  # TODO2 Cache it and next one
  def resource_exist? resource_name    
    self_ancestors_and_namespaces do |klass|
      return true if VResource.resource_exist? klass, resource_name          
    end
    return false
  end  
  cache_method_with_params :resource_exist?
  
  def [] resource_name
    self_ancestors_and_namespaces do |klass|
      if VResource.resource_exist? klass, resource_name
        return VResource.resource_get(klass, resource_name)
      end  
    end
    raise VResource::NotExist, "Resource '#{resource_name}' for Class '#{self.name}' doesn't exist!", caller
  end
  cache_method_with_params :[]
  
  def []= resource_name, value
    VResource.resource_set self.name, resource_name, value
  end    
end