require 'spec_helper'

describe 'AwesomeDelete' do
  describe 'delete projects' do
    let(:project_1) { Project.create }
    let(:project_2) { Project.create }
    let(:project_3) { Project.create }
    let!(:task_1) { Task.create project: project_1 }
    let!(:task_2) { Task.create project: project_1 }
    let!(:task_3) { Task.create project: project_3 }
    let!(:item_1) { Item.create type: 'Item::A', task: task_1 }
    let!(:item_2) { Item.create type: 'Item::B', task: task_1 }
    let!(:item_3) { Item.create type: 'Item::C', task: task_2 }
    let!(:option_1) { Option.create item: item_3 }
    let!(:option_2) { Option.create item: item_3 }
    let!(:comment_1) { Comment.create commentable: project_1 }
    let!(:comment_2) { Comment.create commentable: project_2 }
    let!(:user) { User.create project: project_1 }

    it 'destroys associated tasks' do
      expect {
        Project.delete_collection [project_1, project_2].map(&:id)
      }.to change { Task.count }.by -2
    end

    it 'returns the deleted projects count' do
      count = Project.delete_collection [project_1, project_2].map(&:id)
      expect(count).to eq 2
    end

    it 'destroys the items' do
      expect {
        Project.delete_collection [project_1, project_2].map(&:id)
      }.to change { Item.count }.by -3
    end

    it 'destroys the options' do
      expect {
        Project.delete_collection [project_1, project_2].map(&:id)
      }.to change { Option.count }.by -2
    end

    it 'destroys the comments' do
      expect {
        Project.delete_collection [project_1, project_2].map(&:id)
      }.to change { Comment.count }.by -2
    end

    it 'destroys the user' do
      expect {
        Project.delete_collection [project_1, project_2].map(&:id)
      }.to change { User.count }.by -1
    end
  end

  describe 'delete tasks' do
    let(:project) { Project.create }
    let!(:task_1) { Task.create project: project }
    let!(:task_2) { Task.create project: project }

    it 'touchs the project' do
      expect {
        Task.delete_collection [task_1, task_2].map(&:id)
      }.to change { project.reload.updated_at }
    end

    it 'updates the project tasks_count' do
      expect {
        Task.delete_collection [task_1, task_2].map(&:id)
      }.to change { project.reload.tasks_count }.by -2
    end
  end

  describe 'delete comments' do
    let!(:project) { Project.create }
    let!(:comment_1) { Comment.create commentable: project }
    let!(:comment_2) { Comment.create commentable: project }

    it 'touchs the project' do
      expect {
        Comment.delete_collection [comment_1, comment_2].map(&:id)
      }.to change { project.reload.updated_at }
    end

    it 'updates the project comments_count' do
      expect {
        Comment.delete_collection [comment_1, comment_2].map(&:id)
      }.to change { project.reload.comments_count }.by -2
    end
  end

  describe '.find_all_association_names' do
    it 'finds all association names that will be destroyed' do
      expected = %w(Task Item Option Comment User)
      result = []
      Project.find_all_association_names(result)
      expect(result).to match_array expected
    end
  end

  describe 'set all_association_names (only for test)' do
    let(:project) { Project.create }
    let!(:task_1) { Task.create project: project }
    let!(:task_2) { Task.create project: project }

    it 'doesnt touch the project' do
      expect {
        Task.delete_collection [task_1, task_2].map(&:id), ['Project', 'Task']
      }.not_to change { project.reload.updated_at }
    end

    it 'doesnt update the project tasks_count' do
      expect {
        Task.delete_collection [task_1, task_2].map(&:id), ['Project', 'Task']
      }.not_to change { project.reload.tasks_count }
    end
  end
end
