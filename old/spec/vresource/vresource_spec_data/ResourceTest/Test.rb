require 'ActivePoint/require'

#y({:en => WGUIExt::Editors::RichTextData.new})

v = ObjectModel::Types::ObjectType.yaml_load %{--- 
:en: !ruby/object:WGUIExt::Editors::RichTextData 
  resources: []

  text: ""}

p v