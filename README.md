# awesome_delete
> Recursive delete appropriately

Recursively delete a collection and its all assoication with less sqls.
It thinks about the following
- STI (delete the associations of subclass)
- polymorphism
- counter_cache, touch (avoid to unnecessary handle)

## Install

```ruby
gem install awesome_delete
```

## Example

```ruby
class Form < ActiveRecord::Base
  has_many :fields, dependent: :destroy
end

class Field < ActiveRecord::Base
  has_many :options, dependent: :destroy
end

class Option < ActiveRecord::Base
end

# it deletes forms, fields and options
Form.delete_collection [1,4,5]
```

Overwrite __delete_collection class method if not satisfy your need.
