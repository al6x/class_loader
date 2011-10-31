require 'rspec_ext'
require "class_loader"

describe 'Autoloading classes' do
  it do
    with_load_path "/Users/alex/projects/class_loader/spec/class_loader_spec/after" do
      exp = mock
      exp.should_receive :callback_fired
      ClassLoader.after 'SomeClass' do |klass|
        exp.callback_fired
      end
      SomeClass
    end
  end
end