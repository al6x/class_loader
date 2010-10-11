module ClassLoader
  class FileSystemAdapter
    attr_reader :translator
    
    def initialize class_name_translator
      @translator = class_name_translator
      @paths, @watched_paths, @file_name_cache = [], [], {}
      @watched_files, @first_check = {}, true
    end
    
    def exist? class_name
      !!to_file_path(class_name)
    end
    alias_method :exists?, :exist?
    
    def read class_name      
      file_path = to_file_path class_name
      return nil unless file_path
      
      if file_path =~ /\.rb$/
        File.open(file_path){|f| f.read}        
      else
        "module #{class_name}; end;"
      end  
    end
    
    def to_file_path class_name
      file_path, exist = @file_name_cache[class_name] || []
      unless exist
        file_name = translator.to_file_path class_name
        file_path = catch :found do
          # files
          paths.each do |base|
            try = "#{base}/#{file_name}.rb"
            if File.exist? try
              throw :found, try
            end
          end
          
          # dirs
          paths.each do |base|
            try = "#{base}/#{file_name}"
            if File.exist? try
              throw :found, try
            end
          end
          
          nil
        end
        
        @file_name_cache[class_name] = [file_path, true]
      end
      file_path
    end
    
    def to_class_name normalized_path
      raise "Internal error, file_name should be absolute path (#{normalized_path})!" unless normalized_path =~ /^\//  
      raise "Internal error, file_name should be without .rb suffix (#{normalized_path})!" if normalized_path =~ /\.rb$/  
      
      if base_path = paths.find{|path| normalized_path.start_with? path}
        normalized_name = normalized_path.sub(base_path, '')
        translator.to_class_name(normalized_name)
      else
        nil
      end
    end
    
    def add_path path, watch = false      
      path = File.expand_path(path)
      raise "#{path} already added!" if paths.include? path
      
      paths << path
      watched_paths << path if watch
    end
    
    def clear
      @paths, @watched_paths, @file_name_cache = [], [], {}
      @watched_files, @first_check = {}, true
    end    
        
    def each_changed_class &block
      if @first_check
        each_watched_file{|file_path, relative_name| remember_file file_path}
        @first_check = false
      else
        each_watched_file do |file_path, relative_name|
          if file_changed? file_path
            remember_file file_path
            
            normalized_name = relative_name.sub(/\.rb$/, "")
            block.call translator.to_class_name(normalized_name)
          end
        end
      end      
    end
    
    def each_class &block
      @paths.each do |base_path|          
        Dir.glob("#{base_path}/**/*.rb").each do |file_path|
          normalized_path = file_path.sub(/\.rb$/, "")
          
          normalized_name = normalized_path.sub(base_path, '')
          class_name = translator.to_class_name(normalized_name)
          block.call class_name
        end
      end
    end
    
    protected
      attr_reader :paths, :watched_paths, :watcher, :watched_files      
      
      def each_watched_file &block
        @watched_paths.each do |base_path|          
          Dir.glob("#{base_path}/**/*.rb").each do |file_path|
            relative_name = file_path.sub(base_path, '')
            if translator.is_it_class? relative_name
              block.call file_path, relative_name
            end
          end
        end
      end
      
      def file_changed? path        
        old_time = watched_files[path]
        old_time == nil or old_time != File.mtime(path)
      end

      def remember_file path
        watched_files[path] = File.mtime(path)
      end
      
  end
end