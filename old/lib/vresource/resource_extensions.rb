VResource.register_resource_extension(
  ".yaml",
  lambda{|data, klass, name| YAML.load(data)}, 
  lambda{|data, klass, name| YAML.dump(data)}
)

VResource.register_resource_extension(
  ".rb",
  lambda{|data, klass, name|
    script = ClassLoader.wrap_inside_namespace(klass, data)
    eval script, TOPLEVEL_BINDING, "#{klass.name}/#{name}"
  }, 
  lambda{|data, klass, name| raise "Writing '.rb' Resource isn't supported!"}
)