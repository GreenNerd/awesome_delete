class Project < ActiveRecord::Base
end

class Form < ActiveRecord::Base
  has_many :fields, dependent: :destroy
  has_many :responses, as: :responseable, dependent: :destroy
end

class Field < ActiveRecord::Base
  belongs_to :form, touch: true

  def destroy
    super
    #for test
    ActiveRecord::Base.logger.info('Delete entry by destroy.')
  end
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
  def destroy
    super
    #for test
    ActiveRecord::Base.logger.info('Delete option by destroy.')
  end
end

class Response < ActiveRecord::Base
  has_many :entries, dependent: :destroy
  belongs_to :responseable, polymorphic: true
end

class Entry < ActiveRecord::Base
  after_destroy :handle

  def destroy
    super
    #for test
    ActiveRecord::Base.logger.debug('Delete entry by destroy.')
  end

  private

  def handle
    ActiveRecord::Base.logger.info('Doing other things.')
  end
end