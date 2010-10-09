module VResource
  class FileSystemProvider
    attr_accessor :directories
    
    def initialize directories = File.expand_path('.')
      @directories = Array(directories).collect{|path| File.expand_path path}
    end
    
    def class_get class_name
      path = ensure_exist!(real_class_path(class_name))
      
      if File.directory? path
        "module #{File.basename(path)}; end;"
      else
        File.read path
      end      
    end
    
    # It updates existing class, if class doesn't exist it creates one in directory provided by filter
    def class_set class_name, data, directory_for_class_file = nil
      directory_for_class_file ||= Dir.getwd
      directory_for_class_file = File.expand_path directory_for_class_file
      unless directories.include? directory_for_class_file
        raise "Dirctories should include '#{directory_for_class_file}'!"
      end
      
      path = real_class_path class_name      
      unless path
        path = class_to_files(class_name).select{|f| f.include?(directory_for_class_file)}.first
        dir = path.sub(/\w+\.rb/, "")
        FileUtils.mkdir dir unless dir.empty? or File.exist? dir      
      end
      
      length = File.write path, data
      
      reloader.remember_file path
      return length
    end
    
    def class_exist? class_name
      real_class_path(class_name) != nil
    end
    
    def class_delete class_name
      path = real_class_path class_name
      File.delete path if path
    end
    
    #    def class_namespace_exist? namespace_name
    #      File.exist? class_to_basefile(namespace_name)
    #    end
    
    # First search for "./class_name.resource_name" files
    # And then search for "./class_name.res/resource_name" files
    def resource_get class_name, resource_name
      path = ensure_exist!(real_resource_path(class_name, resource_name))
      
      File.read path
    end
    
    def resource_delete class_name, resource_name
      path = real_resource_path class_name, resource_name
      File.delete path if path      
    end
    
    # It can only update existing resource, it can't create a new one
    # First search for the same resource and owerwrites it
    # If such resource doesn't exists writes to
    # "./class_name.res/resource_name" file.
    def resource_set class_name, resource_name, data
      class_path = ensure_exist!(real_class_path(class_name))
      
      path = real_resource_path class_name, resource_name
      unless path
        class_path = class_path.sub(/\.rb$/, "")
        dir = "#{class_path}.res"        
        FileUtils.mkdir dir unless File.exist? dir
        path = "#{dir}/#{resource_name}"
      end
      
      length = File.write path, data
      reloader.remember_file path
      return length
    end
    
    def resource_exist? class_name, resource_name
      class_path = ensure_exist!(real_class_path(class_name))
      
      real_resource_path(class_name, resource_name) != nil
    end            
    
    #    def class_to_virtual_path class_name
    #      result = nil
    #      if @cache.include? class_name
    #        result = @cache[class_name]
    #      else
    #        result = nil
    #        path = "#{base_dir}/#{class_name.gsub("::", "/")}"
    #        if File.exist? path
    #          result = path
    #        else
    #          path2 = "#{path}.rb"
    #          if File.exist? path2
    #            result = path
    #          else
    #            path3 = "#{path}.res"
    #            if File.exist? path3
    #              result = path      
    #            end
    #          end        
    #        end
    #        @cache[class_name] = result
    #      end            
    #      
    #      if result
    #        return result
    #      else
    #        raise Resource::NotExist, "Class '#{class_name}' doesn't Exist!"
    #      end
    #    end
    
    # Different Providers can use different class path interpretation.
    # So we return virtual path only if this path really exist.
    def translate_class_name_to_virtual_file_name class_name
      path = ensure_exist!(real_class_path(class_name), "Class '#{class_name}' doesn't Exist!")      
      File.expand_path path
    end
    cache_method_with_params :translate_class_name_to_virtual_file_name
    
    def reloader
      @reloader ||= FileSystemReloader.new directories
    end
    
    protected  
      def ensure_exist! path, msg = ""
        raise VResource::NotExist, msg unless path
        path
      end
    
      def real_class_path class_name
        path = class_to_files(class_name).find{|f| File.exist? f}
        path ||= class_to_basefiles(class_name).find{|f| File.exist? f}
        return path
      end
    
      def real_resource_path class_name, resource_name
        file = class_to_basefiles(class_name).collect{|f| "#{f}.#{resource_name}"}.find{|f| File.exist? f}      
        file ||= class_to_basefiles(class_name).collect{|f| "#{f}.res/#{resource_name}"}.find{|f| File.exist? f}
        return file
      end
    
      def class_to_files class_name            
        class_to_basefiles(class_name).collect{|name| "#{name}.rb"}
      end
    
      # Different Providers can use different class path interpretation.
      # So we return virtual path only if this path really exist.
      def class_to_basefiles class_name
        relative = class_name.gsub("::", "/")
        return directories.collect{|dir| "#{dir}/#{relative}"}
      end    
    
      #      Doesn't make Sense for Virtual Resource System
      #      def resource_path class_name, resource_name
      #        @monitor.synchronize do
      #          path = "#{class_to_path(class_name)}.#{resource_name}"
      #          if File.exist? path
      #            return path
      #          else
      #            path = "#{class_to_path(class_name)}.res/#{resource_name}"
      #            if File.exist? path
      #              return path
      #            else
      #              nil
      #            end
      #          end
      #        end
      #      end
    
  end
end