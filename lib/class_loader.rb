autoload :ClassLoader, 'class_loader/class_loader'

class Module
  alias_method :const_missing_without_autoload, :const_missing
  def const_missing const
    ClassLoader.load(self, const) || const_missing_without_autoload(const)
  end
end