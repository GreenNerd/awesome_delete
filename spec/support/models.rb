class Project < ActiveRecord::Base
end

class User < ActiveRecord::Base
end

class Form < ActiveRecord::Base
  has_many :fields, dependent: :destroy
  has_many :responses, as: :responseable, dependent: :destroy
  belongs_to :formable, polymorphic: true, touch: true, counter_cache: true
  belongs_to :user, touch: true, counter_cache: true
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
  after_commit :test

  def test
    Logger.send "option_after_commit", 'Doing other things.'
  end
end

class Response < ActiveRecord::Base
  has_many :entries, dependent: :destroy
  belongs_to :responseable, polymorphic: true
end

class Entry < ActiveRecord::Base
  before_destroy :handle1
  after_destroy :handle2
  belongs_to :response, counter_cache: true

  private

  def handle1
    Logger.send "entry_before_destroy", 'Doing other things.'
  end

  def handle2
    Logger.send "entry_after_destroy", 'Doing other things.'
  end
end

class ActiveRecord::Relation
  def update_all updates
    #for test
    if updates[:updated_at] || updates['updated_at']
      Logger.send "#{model.name.downcase}_touch", 'Touching'
    elsif updates.keys.find { |key| key =~ /.*_count$/ }
      Logger.send "#{model.name.downcase}_update_counter", 'Updating counter'
    end

    raise ArgumentError, "Empty list of attributes to change" if updates.blank?

    stmt = Arel::UpdateManager.new(arel.engine)

    stmt.set Arel.sql(@klass.send(:sanitize_sql_for_assignment, updates))
    stmt.table(table)
    stmt.key = table[primary_key]

    if joins_values.any?
      @klass.connection.join_to_update(stmt, arel)
    else
      stmt.take(arel.limit)
      stmt.order(*arel.orders)
      stmt.wheres = arel.constraints
    end

    bvs = arel.bind_values + bind_values
    @klass.connection.update stmt, 'SQL', bvs
  end
end

class Logger
  def self.method_missing(method, *args, &block)
    args
  end
end