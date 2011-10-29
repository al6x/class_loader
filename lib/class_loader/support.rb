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
      list = class_name.split("::")
      if list.size > 1
        list.pop
        return eval(list.join("::"), TOPLEVEL_BINDING, __FILE__, __LINE__)
      else
        return nil
      end
    end
  end
end