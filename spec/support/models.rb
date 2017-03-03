class Project < ActiveRecord::Base
  has_many :tasks, dependent: :destroy
  has_many :comments, as: :commentable, dependent: :destroy
  has_one :author, dependent: :delete, class_name: 'User'
end

class Task < ActiveRecord::Base
  belongs_to :project, touch: true, counter_cache: true
  has_many :items, dependent: :destroy
end

class Item < ActiveRecord::Base
  belongs_to :task
end

class Item::A < Item
end

class Item::B < Item
end

class Item::C < Item
  has_many :options, dependent: :delete_all, foreign_key: :item_id
end

class Option < ActiveRecord::Base
  belongs_to :item
end

class Comment < ActiveRecord::Base
  belongs_to :commentable, polymorphic: true, touch: true, counter_cache: true
end

class User < ActiveRecord::Base
  belongs_to :project
end
