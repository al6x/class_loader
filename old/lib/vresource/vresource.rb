module VResource      
  
  class NotExist < StandardError    
  end

  @providers = []
  class << self
    include Observable2
    
    def resource_extensions; @resource_extensions ||= {} end
    
    def add_resource_provider provider
      @providers.unshift provider
    end
    
    def providers
      raise "There's no any Resource Provider!" if @providers.empty?
      @providers
    end
    
    def register_resource_extension extension, load, save
      resource_extensions[extension] = load, save
    end
    
    def unregister_resource_extension extension
      resource_extensions.delete extension
    end                        
    
    # Returns from first Provider that contains this Class.
    def class_get class_name
      providers.each do |p|
        begin
          return p.class_get(class_name) 
        rescue NotExist;
        end
      end
      raise "Class '#{class_name}' doesn't exist!"
    end
    
    # Search for first Provider that contains Class Namespace and creates Class in it, then exits.
    def class_set class_name, data, *args      
      namespace = Module.namespace_for class_name
      namespace = namespace ? namespace.to_s : nil
      found = false
      providers.each do |p|
        next unless !namespace or p.class_exist?(namespace)
        p.class_set class_name, data, *args
        found = true
        break
      end
      raise "Namespace '#{namespace}' doesn't exist!" unless found
    end
    
    def class_exist? class_name
      providers.any?{|p| p.class_exist? class_name}
    end
    
    # Deletes in each Providers.
    def class_delete class_name
      providers.each{|p| p.class_delete class_name}
    end
    
#      def class_namespace_exist? namespace_name
#        @monitor.synchronize do
#          providers.any?{|p| p.class_namespace_exist? namespace_name}
#        end
#      end
    
    # Search each Provider that contains this Class and returns first found Resource.
    def resource_get klass, resource_name        
      providers.each do |p|
        next unless p.class_exist?(klass.name)
        begin
          data = p.resource_get(klass.name, resource_name)
          
          if data
            extension = File.extname(resource_name)
            if resource_extensions.include? extension
              load, save = resource_extensions[extension]
              data = load.call data, klass, resource_name
            end
          end
          
          return data
        rescue NotExist;
        end
      end
      raise "Resource '#{resource_name}' for Class '#{klass.name}' doesn't exist!"
    end
    
    # Deletes Resource in all Providers.
    def resource_delete klass, resource_name
      providers.each do |p|
        next unless p.class_exist?(klass.name)
        p.resource_delete klass.name, resource_name    
      end
    end
    
    # Set Resource in fist Provider that contains this Class.
    def resource_set klass, resource_name, data
      extension = File.extname(resource_name)
      if resource_extensions.include? extension
        load, save = resource_extensions[extension]
        data = save.call data, klass, resource_name
      end
      
      found = false
      providers.each do |p|
        next unless p.class_exist?(klass.name)
        p.resource_set klass.name, resource_name, data
        found = true
        break
      end
      
      raise "Class '#{klass.name}' doesn't exist!" unless found
    end
    
    # Check also for Class existence.
    def resource_exist? klass, resource_name
      providers.any? do |p|
        next unless p.class_exist?(klass.name)
        p.resource_exist? klass.name, resource_name
      end
    end                        
    
    def translate_class_name_to_virtual_file_name class_name
      providers.each do |p|
        begin
          return p.translate_class_name_to_virtual_file_name class_name 
        rescue NotExist;
        end
      end
      raise "Class '#{class_name}' doesn't exist!"          
    end
    
    def hook!; ClassLoader.hook! end
    def unhook!; ClassLoader.unhook! end
    
    synchronize_all_methods
    
    # 
    # Handy :autoload_dir method
    # TODO2 refactor it and improove
    # 
    def start_reloader_if_needed        
      if @fs_provider and !@reloader_started
        @fs_provider.reloader.start
        @reloader_started = true
      end
    end
    
    def autoload_dir dir
      initialize_vresource
      start_reloader_if_needed
      @fs_provider.directories << dir
    end
        
    def initialize_vresource
      unless @fs_provider          
        @fs_provider = FileSystemProvider.new([])
        add_resource_provider @fs_provider
        add_observer ClassLoader
        hook!
      end
    end
    protected :initialize_vresource
#      def class_to_virtual_path class_name
#        @monitor.synchronize do
#          providers.each do |p|
#            begin
#              return p.class_to_virtual_path class_name 
#            rescue NotExist;
#            end
#          end
#          raise "Class '#{class_name}' doesn't exist!"
#        end
#      end
  end 
end