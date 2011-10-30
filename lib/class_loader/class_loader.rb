require 'class_loader/support'
require 'monitor'

module ClassLoader
  @loaded_classes, @after_callbacks = {}, {}
  @monitor = Monitor.new
  class << self
    attr_reader :loaded_classes, :monitor

    # Hierarchically searching for class file, according to modules hierarchy.
    #
    # For example, let's suppose that `C` class defined in '/lib/a/c.rb' file, and we referencing it
    # in the `A::B` namespace, like this - `A::B::C`, the following files will be checked:
    #
    # - '/lib/a/b/c.rb' - there's nothing, moving up in hierarchy.
    # - '/lib/a/c.rb' - got and load it.
    def load namespace, const
      monitor.synchronize do
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
            unless e.message =~ /no such file.*#{Regexp.escape(class_file_name)}/
              raise e.class, e.message, filter_backtrace(e.backtrace)
            end
            false
          end

          if loaded
            # Checking that class hasn't been loaded previously, sometimes it may be caused by
            # weird class definition code.
            if loaded_classes.include? class_name
              msg = "something wrong with '#{const}' referenced from '#{original_namespace}' scope!"
              raise NameError, msg, filter_backtrace(caller)
            end

            # Checking that class defined in correct namespace, not the another one.
            unless namespace ? namespace.const_defined?(const, false) : Object.const_defined?(const, false)
              msg = "class name '#{class_name}' doesn't correspond to file name '#{class_file_name}'!"
              raise NameError, msg, filter_backtrace(caller)
            end

            # Getting the class itself.
            klass = namespace ? namespace.const_get(const, false) : Object.const_get(const, false)

            # Firing after callbacks.
            if callbacks = after_callbacks[klass.name] then callbacks.each{|c| c.call klass} end

            loaded_classes[class_name] = klass

            return klass
          end

          # Moving to higher namespace.
          global_also_tried = namespace == nil
          namespace = Module.namespace_for namespace.name if namespace
        end until global_also_tried

        return nil
      end
    end

    # Eagerly load all classes in paths.
    def preload *paths
      monitor.synchronize do
        paths.each do |path|
          Dir.glob("#{path}/**/*.rb").each do |class_path|
            class_file_name = class_path.sub("#{path}/", '').sub(/\.rb$/, '')
            require class_file_name
          end
        end
      end
    end

    # Watch and reload files.
    def watch *paths
      paths.each{|path| watcher.paths << path unless watcher.paths.include? path}
      watcher.start
    end

    def watcher
      require 'class_loader/watcher'
      @watcher ||= ClassLoader::Watcher.new monitor
    end

    def after class_name, &block
      (@after_callbacks[class_name] ||= []) << block
    end

    def filter_backtrace backtrace
      backtrace.reject{|path| path.include?("/lib/class_loader") or path.include?('monitor.rb')}
    end

    protected
      attr_reader :after_callbacks

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
  end
end