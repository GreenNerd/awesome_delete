ActiveRecord::Schema.define(:version => 0) do
  create_table :projects, :force => true do |t|
    t.string :title
    t.integer :tasks_count
    t.integer :comments_count
    t.datetime :created_at
    t.datetime :updated_at
  end

  create_table :tasks, :force => true do |t|
    t.string :title
    t.integer :project_id
    t.datetime :created_at
    t.datetime :updated_at
  end

  create_table :items, :force => true do |t|
    t.string :name
    t.integer :task_id
    t.string :type
    t.datetime :created_at
    t.datetime :updatedat
  end

  create_table :options, :force => true do |t|
    t.string :name
    t.integer :item_id
    t.datetime :created_at
    t.datetime :updated_at
  end

  create_table :comments, :force => true do |t|
    t.string :content
    t.integer :commentable_id
    t.string :commentable_type
    t.datetime :created_at
    t.datetime :updated_at
  end

  create_table :users, :force => true do |t|
    t.string :name
    t.integer :project_id
    t.datetime :created_at
    t.datetime :updated_at
  end
end
