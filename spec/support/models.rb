class Project < ActiveRecord::Base
end

class Form < ActiveRecord::Base
  has_many :fields, dependent: :destroy
  has_many :responses, as: :responseable, dependent: :destroy
  belongs_to :formable, polymorphic: true, touch: true
end

class Field < ActiveRecord::Base
  belongs_to :form, touch: true
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
  after_destroy :handle

  private

  def handle
    ActiveRecord::Base.logger.info('Doing other things.')
  end
end