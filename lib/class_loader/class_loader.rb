require 'class_loader/support'

module ClassLoader
  @loaded_classes = {}
  class << self
    attr_reader :loaded_classes

    # Hierarchically searching for class file, according to modules hierarchy.
    #
    # For example, let's suppose that `C` class defined in '/lib/a/c.rb' file, and we referencing it
    # in the `A::B` namespace, like this - `A::B::C`, the following files will be checked:
    #
    # - '/lib/a/b/c.rb' - there's nothing, moving up in hierarchy.
    # - '/lib/a/c.rb' - got and load it.
    def load namespace, const
      original_namespace = namespace
      namespace = nil if namespace == Object or namespace == Module
      target_namespace = namespace

      # Need this hack to work with anonymous classes.
      namespace = eval "#{name_hack(namespace)}" if namespace

      # Hierarchically searching for class name.
      begin
        class_name = namespace ? "#{namespace.name}::#{const}" : const.to_s
        class_file_name = get_file_name class_name

        # Trying to load class file, if its exist.
        loaded = begin
          require class_file_name
          true
        rescue LoadError => e
          # Not the best way - hardcoding error messages, but it's the fastest way
          # to check existence of file & load it.
          raise e unless e.message =~ /no such file.*#{Regexp.escape(class_file_name)}/
          false
        end

        if loaded
          # Checking that class hasn't been loaded previously, sometimes it may be caused by
          # weird class definition code.
          if loaded_classes.include? class_name
            raise_without_self NameError, \
              "something wrong with '#{const}' referenced from '#{original_namespace}' scope!"
          end

          # Checking that class defined in correct namespace, not the another one.
          unless namespace ? namespace.const_defined?(const, false) : Object.const_defined?(const, false)
            raise_without_self NameError, \
              "class name '#{class_name}' doesn't correspond to file name '#{class_file_name}'!"
          end

          # Getting the class itself.
          klass = namespace ? namespace.const_get(const, false) : Object.const_get(const, false)

          loaded_classes[class_name] = klass

          return klass
        end

        # Moving to higher namespace.
        global_also_tried = namespace == nil
        namespace = Module.namespace_for namespace.name if namespace
      end until global_also_tried

      return nil
    end

    # Dynamic class loading is not thread safe (known Ruby bug), to workaround it
    # You can forcefully preload all Your classes in production when Your app starts.
    def preload path
      Dir.glob("#{path}/**/*.rb").each do |class_path|
        class_file_name = class_path.sub("#{path}/", '').sub(/\.rb$/, '')
        require class_file_name
      end
    end

    # Watch and reload files.
    def watch path
      watcher.paths << path
      watcher.start
    end

    def watcher
      require 'class_loader/watcher'
      @watcher ||= ClassLoader::Watcher.new
    end

    protected
      # Use this method to define class name to file name mapping, by default it uses underscored paths,
      # but You can override this method to use camel case for example.
      def get_file_name class_name
        class_name.underscore
      end

      # Module.name doesn't works correctly for Anonymous classes.
      # try to execute this code:
      #
      #     class Module
      #       def const_missing const
      #         p self.to_s
      #       end
      #     end
      #
      #     class A
      #       class << self
      #         def a
      #           p self
      #           MissingConst
      #         end
      #       end
      #     end
      #
      #     A.a
      #
      # the output will be:
      #
      #     A
      #     "#<Class:A>"
      #
      def name_hack namespace
        if namespace
          result = namespace.to_s.gsub("#<Class:", "").gsub(">", "")
          result =~ /^\d/ ? "" : result
        else
          ""
        end
      end

      def raise_without_self exception, message
        raise exception, message, caller.select{|path| path !~ /\/lib\/class_loader\//}
      end
  end
end