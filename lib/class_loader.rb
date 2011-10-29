autoload :ClassLoader, 'class_loader/class_loader'

class Module
  alias_method :const_missing_without_cl, :const_missing
  def const_missing const
    ClassLoader.load(self, const) || begin
      const_missing_without_cl(const)
    rescue => e
      # Removing ClassLoader from backtrace.
      raise e.class, e.message, ClassLoader.filter_backtrace(e.backtrace)
    end
  end
end