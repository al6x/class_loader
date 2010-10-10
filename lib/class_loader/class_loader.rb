require 'monitor'

module ClassLoader
  @observers = []
  SYNC = Monitor.new
  
  class << self        
    # 
    # Class loading logic
    # 
    attr_accessor :error_on_defined_constant
    def loaded_classes; @loaded_classes ||= {} end            
    
    def load_class namespace, const, reload = false            
      SYNC.synchronize do
        namespace = nil if namespace == Object or namespace == Module
        target_namespace = namespace
      
        # Name hack (for anonymous classes)
        namespace = eval "#{name_hack(namespace)}" if namespace
      
        class_name = namespace ? "#{namespace.name}::#{const}" : const
        simple_also_tried = false
        begin
          simple_also_tried = (namespace == nil)
        
          if try_load(class_name, const)
            defined_in_home_scope = namespace ? namespace.const_defined?(const) : Object.const_defined?(const)            
          
            unless defined_in_home_scope
              msg = "Class Name '#{class_name}' doesn't correspond to File Name '#{adapter.to_file_path(class_name)}'!"
              raise_without_self NameError, msg
            end
                        
            unless reload
              if loaded_classes.include? class_name
                if error_on_defined_constant  
                  raise_without_self NameError, "Class '#{class_name}' is not defined in the '#{target_namespace}' Namespace!"
                else
                  warn "Warn: Class '#{class_name}' is not defined in the '#{target_namespace}' Namespace!"
                  puts caller
                end
              end
            end
            
            result = namespace ? namespace.const_get(const) : Object.const_get(const)
          
            loaded_classes[class_name] = target_namespace
            notify_observers result
            return result
          elsif namespace
            namespace = Module.namespace_for(namespace.name)
            class_name = namespace ? "#{namespace.name}::#{const}" : const
          end
        end until simple_also_tried
        
        raise_without_self NameError, "uninitialized constant '#{class_name}'!"
      end
    end
    
    def reload_class class_name
      SYNC.synchronize do
        class_name = class_name.sub(/^::/, "")
        namespace = Module.namespace_for(class_name)
        name = class_name.sub(/^#{namespace}::/, "")      
        
        # removing old class
        class_container = (namespace || Object)
        class_container.send :remove_const, name if class_container.const_defined? name
        
        return load_class namespace, name, true
      end
    end
      
    def wrap_inside_namespace namespace, script
      nesting = []
      if namespace
        current_scope = ""
        namespace.name.split("::").each do |level|
          current_scope += "::#{level}"
          type = eval current_scope, TOPLEVEL_BINDING, __FILE__, __LINE__
          nesting << [level, (type.class == Module ? "module" : "class")]
        end
      end
      begining = nesting.collect{|l, t| "#{t} #{l};"}.join(' ')
      ending = nesting.collect{"end"}.join('; ')
      return "#{begining}#{script} \n#{ending}"
    end
    
    
    # 
    # Utilities
    #     
    def autoload_dir path, watch = false, start_watch_thread = true
      hook!
      start_watching! if watch and start_watch_thread
      adapter.add_path path, watch
    end
    
    def clear
      self.adapter = nil
      self.observers = []
      self.error_on_defined_constant = false
    end
    
    attr_accessor :observers    
    def add_observer &block; observers << block end
    def notify_observers o
      observers.each{|obs| obs.call o}
    end
    
    def hook!
      return if @hooked

      ::Module.class_eval do
        alias_method :const_missing_without_cl, :const_missing
        def const_missing const
          return ClassLoader.load_class self, const.to_s
        end
      end
      @hooked = true
    end
    
    attr_writer :adapter
    def adapter
      @adapter ||= default_adapter
    end
    
    
    # 
    # Watcher thread
    # 
    attr_accessor :watch_interval
    def start_watching!
      unless watching_thread      
        self.watching_thread = Thread.new do        
          while true
            sleep(watch_interval || 2)
            adapter.each_changed_class do |class_name|
              puts "reloading #{class_name}"
              reload_class class_name              
            end
          end
        end
      end
    end

    def stop_watching!
      if watching_thread
        watching_thread.kill
        self.watching_thread = nil
      end
    end
    
    def preload!
      adapter.each_class do |class_name|
        reload_class class_name
      end
    end
    
    
    protected
      def default_adapter
        adapter = ChainedAdapter.new        
        adapter.adapters << FileSystemAdapter.new(CamelCaseTranslator)    
        adapter.adapters << FileSystemAdapter.new(UnderscoredTranslator)
        adapter        
      end
      
      def try_load class_name, const
        if adapter.exist? class_name
          script = adapter.read class_name
          script = wrap_inside_namespace Module.namespace_for(class_name), script          
          file_path = adapter.to_file_path(class_name)          
          eval script, TOPLEVEL_BINDING, file_path
        else
          return false
        end
        return true
      end
      
      def raise_without_self exception, message
        raise exception, message, caller.select{|path| path !~ /\/lib\/class_loader\//}
      end
    
      def name_hack namespace
        if namespace
          namespace.to_s.gsub("#<Class:", "").gsub(">", "")
        else
          ""
        end
        # Namespace Hack description
        # Module.name doesn't works correctly for Anonymous classes.
        # try to execute this code:
        #
        #class Module
        #  def const_missing const
        #    p self.to_s
        #  end
        #end
        #
        #class A
        #    class << self
        #        def a
        #            p self
        #            MissingConst
        #        end
        #    end
        #end
        #
        #A.a
        #
        # the output will be:
        # A
        # "#<Class:A>"
        #
      end
  end
end