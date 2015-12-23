# awesome_delete
> Recursive delete appropriately

Recursively delete a collection and its all assoication with less sqls.
It thinks about the following
- STI (delete the associations of subclass)
- polymorphism
- counter_cache, touch (avoid to unnecessary handle)
- callbacks

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
end

Form.delete_collection [1,4,5]
```
The class method `execute_callbacks` will execute callbacks.
Overwriting it maybe a better choice.
eg:
```ruby
class CloudFile < ActiveRecord::Base
  before_destroy :test
  after_destroy :remove_file

  def self.execute_callbacks ids
    # before_destroy
    put 'someting'

    where(id: ids).delete_all # delete self

    # after_destroy
    keys = where(id: ids).pluck(:key)
    # do something with all keys
  end

  def test
    put 'someting'
  end

  def remove_file key
    HttpClient.send_request key
  end
end
```
