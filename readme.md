# Automatically finds and loads classes for your Ruby App

## Overview
There's only one method - :autoload_dir, kind of turbocharged :autoload, it understands namespaces, figure out dependencies and can watch and reload changed files.

Let's say your application has the following structure

	/your_app
		/lib			
			/animals
				/dog.rb
			/zoo.rb

Just point ClassLoader to the directory(ies) your classes are located and it will find and load them automatically

	require 'class_loader'
	autoload_dir '/your_app/lib'
	
	Zoo.add Animals::Dog.new # <= all classes loaded automatically
	
no need for

	# require 'animals/dog'
	# require 'app'
	
you can specify multiple autoload directories, and tell it to watch them

	autoload_dir '/your_app/lib', true # <= provide true as the second argument
	autoload_dir '/your_app/another_lib'	
	
**Note**: In the dog.rb we write just the "class Dog; end", instead of "module Animals; class Dog; end; end', and there are no really the 'Animals' module, ClassLoader smart enough to figure it out that there's should be one by looking at files structure and it will generate it on the fly.

Also you can use CamelCase notation or provide your own class_name/file_path translator, or even provide your own custom resource adapter that for example will look for classes on the net and download them.

There's currently a known bug in Ruby 1.8.x - class loading isn't thread safe, so in production you should preload all your classes

	ClassLoader.preload! if app_in_production?

## Installation

	$ gem install class_loader
	
## Please let me know about bugs and your proposals, there's the 'Issues' tab at the top, feel free to submit.
	
Copyright (c) 2010 Alexey Petrushin http://bos-tec.com, released under the MIT license.