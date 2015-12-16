class Form < ActiveRecord::Base
  has_many :fields, dependent: :destroy
  has_many :responses, as: :responseable, dependent: :destroy
end

class Field < ActiveRecord::Base
  belongs_to :form
end

class Field::A < Field
  has_many :options, dependent: :destroy, foreign_key: 'field_id'
end

class Field::B < Field
  has_many :options, dependent: :destroy, foreign_key: 'field_id'
end

class Field::C < Field
end

class Option < ActiveRecord::Base
end

class Response < ActiveRecord::Base
  has_many :entries, dependent: :destroy
  belongs_to :responseable, polymorphic: true
end

class Entry < ActiveRecord::Base
  after_destroy :test

  private

  def test
    p 'test'
  end
end