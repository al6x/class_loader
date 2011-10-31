class String
  unless method_defined? :underscore
    def underscore
      word = self.dup
      word.gsub!(/::/, '/')
      word.gsub!(/([A-Z]+)([A-Z][a-z])/,'\1_\2')
      word.gsub!(/([a-z\d])([A-Z])/,'\1_\2')
      word.tr!("-", "_")
      word.downcase!
      word
    end
  end
end

class Module
  unless respond_to? :namespace_for
    def self.namespace_for class_name
      @namespace_for_cache ||= {}
      unless @namespace_for_cache.include? class_name
        list = class_name.split("::")
        @namespace_for_cache[class_name] = if list.size > 1
          list.pop
          eval list.join("::"), TOPLEVEL_BINDING, __FILE__, __LINE__
        else
          nil
        end
      end
      @namespace_for_cache[class_name]
    end
  end
end