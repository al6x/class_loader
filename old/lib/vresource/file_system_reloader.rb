module VResource
  class FileSystemReloader
    attr_accessor :directories, :interval, :thread
    
    def initialize directories = Dir.glob("**/lib"), interval = 2
      @files = {}
      self.directories, self.interval = directories, interval      
    end
    
    def start
      self.thread = Thread.new do        
        while true
          sleep interval
          check
        end
      end
    end

    def stop
      if thread
        thread.kill
        self.thread = nil
      end
    end

    def remember_file path
      @files[path] = File.mtime(path)
    end
    
    def check
      reset if @files.empty?
      
      begin
        check_for_changed_files.each do |type, klass, res|                        
          VResource.notify_observers :update_resource, type, klass, res
        end              
      rescue Exception => e
        warn e
      end
    end
    
    def reset
      @files = {}
      all_files.each do |path|
        remember_file path
      end
    end
    
    protected
      def all_files
        directories.inject([]){|list, dir| list + Dir.glob("#{dir}/**/**")}.select{|f| !File.directory?(f)}
      end
    
      def check_for_changed_files        
        changed = []
        all_files.each do |path|
          if file_changed? path
            remember_file path
            changed << file_changed(path)              
          end
        end
        return changed
      end
    
      def file_changed? path        
        old_time = @files[path]
        
        # p [old_time, File.mtime(path), path] if old_time != File.mtime(path)
        
        old_time == nil or old_time != File.mtime(path)
      end
    
      def file_changed path
        begin
          if path =~ /\.rb$/
            path = path.sub(/\.rb$/, "")
            class_name = path_to_class(path)
                                  
            klass = eval class_name, TOPLEVEL_BINDING, __FILE__, __LINE__
            
            # ClassLoader.reload_class(klass)
            
            # @cache.delete class_name
            return :class, klass, nil
          else    
            if path =~ /\.res/
              class_path = path.sub(/\.res.+/, "")
              resource_name = path.sub("#{class_path}.res/", "")
              class_name = path_to_class class_path
            else
              resource_name = path.sub(/.+\./, "")
              class_name = path_to_class path.sub(/\.#{resource_name}$/, "")
            end 
            klass = eval class_name, TOPLEVEL_BINDING, __FILE__, __LINE__
            return :resource, klass, resource_name
          end
        rescue Exception => e
          warn "Can't reload file '#{path}' #{e.message}!"                                        
        end
      end
    
      def path_to_class path
        base_dir = directories.select{|f| path.include? f}.max{|a, b| a.size <=> b.size}
        path.gsub(/^#{base_dir}\//, "").gsub("/", "::")
      end
  end
end