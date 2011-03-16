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
  
  unless method_defined? :camelize
    def camelize first_letter_in_uppercase = true
      if first_letter_in_uppercase
        gsub(/\/(.?)/) { "::#{$1.upcase}" }.gsub(/(?:^|_)(.)/) { $1.upcase }
      else
        self[0].chr.downcase + camelize(lower_case_and_underscored_word)[1..-1]
      end
    end
  end
end

class Module
  unless respond_to? :namespace_for
    # TODO3 cache it?
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