module ClassLoader
  class << self
    include Observable2
    
    attr_accessor :error_on_defined_constant
    def loaded_classes; @loaded_classes ||= {} end
    
    def update_resource type, klass, resource
      if type == :class
        Kernel.print "Reloading #{klass}:"
        reload_class klass.name
        Kernel.print " reloaded.\n"
      end 
    end
    
    def reload_class class_name
      class_name = class_name.sub(/^::/, "")
      namespace = Module.namespace_for(class_name);
      name = class_name.sub(/^#{namespace}::/, "")
      return load_class namespace, name, true
    end
    synchronize_method :reload_class
    
    
    def load_class namespace, const, reload = false            
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
            msg = "Class Name '#{class_name}' doesn't correspond to File Name '#{VResource.translate_class_name_to_virtual_file_name(class_name)}'!"
            raise_without_self NameError, msg, ClassLoader
          end
                        
          unless reload
            if loaded_classes.include? class_name
              if error_on_defined_constant  
                raise_without_self NameError, "Class '#{class_name}' is not defined in the '#{target_namespace}' Namespace!", ClassLoader
              else
                warn "Warn: Class '#{class_name}' is not defined in the '#{target_namespace}' Namespace!"
                puts caller
              end
            end
          end
            
          result = namespace ? namespace.const_get(const) : Object.const_get(const)
          
          loaded_classes[class_name] = target_namespace
          notify_observers :update_class, result
          return result
        elsif namespace
          namespace = Module.namespace_for(namespace.name)
          class_name = namespace ? "#{namespace.name}::#{const}" : const
        end
      end until simple_also_tried
        
      raise_without_self NameError, "uninitialized constant '#{class_name}'!", ClassLoader
    end
    synchronize_method :load_class
      
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
    
    def hook!
      unless @hooked          
        ::Module.class_eval do
          alias_method :const_missing_without_cl, :const_missing
          def const_missing const
            return VResource::ClassLoader.load_class self, const.to_s
          end
        end
        @hooked = true
      end
    end
    
    def unhook!
      if @hooked
        ::Module.class_eval do
          alias_method :const_missing, :const_missing_without_cl
        end
        @hooked = false
      end
    end
    
    protected
    
      def try_load class_name, const                    
        if VResource.class_exist? class_name
          script = VResource.class_get class_name
          script = wrap_inside_namespace Module.namespace_for(class_name), script
          eval script, TOPLEVEL_BINDING, VResource.translate_class_name_to_virtual_file_name(class_name)
          #          elsif Resource.class_namespace_exist? class_name
          #            script = "#{begining} module #{const}; end; #{ending}"
          #            eval script, TOPLEVEL_BINDING, __FILE__, __LINE__
        else
          return false
        end
        return true
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