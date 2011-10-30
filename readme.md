# ClassLoader automatically finds, loads and reloads classes

Suppose there's following directory structure:

    /lib
      /some_class.rb        # class SomeClass; end
      /some_namespace
        /another_class.rb   # class SomeNamespace:AnotherClass; end
      /some_namespace.rb    # module SomeNamespace; end

All these classes will be loaded automatically:

``` ruby
require 'class_loader'

SomeClass
SomeNamespace::AnotherClass
```

No need for `require` or `autoload`:

``` ruby
require 'some_class'
require 'some_namespace'
require 'some_namespace/another_class'

autoload :SomeClass,      'some_class'
autoload :SomeNamespace,  'some_namespace'
module SomeNamespace
  autoload :AnotherClass, 'some_namespace/another_class'
end
```

You can also tell it to watch and reload changes:

``` ruby
ClassLoader.watch 'my_app/lib'
```

Or preload classes eagerly:

``` ruby
ClassLoader.preload 'my_app/lib'
```

## Installation

	$ gem install class_loader

## License

Copyright (c) Alexey Petrushin http://petrush.in, released under the MIT license.