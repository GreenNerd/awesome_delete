require 'spec_helper'

describe 'AwesomeDelete' do

  before(:all) do
    self.class.fixtures :projects, :forms, :fields, :options, :responses, :entries
  end

  describe 'deleting forms' do
    it 'decrements the forms count' do
      form_a = forms(:form_a)
      form_b = forms(:form_b)
      expect {
        Form.delete_collection [form_a.id, form_b.id]
      }.to change { Form.count }.by -2
    end

    it 'touchs the project' do
      form_a = forms(:form_a)
      form_b = forms(:form_b)
      expect {
        Form.delete_collection [form_a.id, form_b.id]
      }.to change { projects(:project_a).reload.updated_at }
    end

    it 'decrements the fields count' do
      form_a = forms(:form_a)
      form_b = forms(:form_b)
      expect {
        Form.delete_collection [form_a.id, form_b.id]
      }.to change { Field.count }.by -3
    end

    it 'decrements the options count' do
      form_a = forms(:form_a)
      form_b = forms(:form_b)
      expect {
        Form.delete_collection [form_a.id, form_b.id]
      }.to change { Option.count }.by -3
    end

    it 'decrements the responses count' do
      form_a = forms(:form_a)
      form_b = forms(:form_b)
      expect {
        Form.delete_collection [form_a.id, form_b.id]
      }.to change { Response.count }.by -3
    end

    it 'decrements the entries count' do
      form_a = forms(:form_a)
      form_b = forms(:form_b)
      expect {
        Form.delete_collection [form_a.id, form_b.id]
      }.to change { Entry.count }.by -3
    end

    it 'executes destroy callback' do
      form_a = forms(:form_a)
      form_b = forms(:form_b)
      expect(ActiveRecord::Base.logger).to receive(:info).with("Doing other things.").exactly(3).times
      Form.delete_collection [form_a.id, form_b.id]
    end
  end

  describe 'destroying fields' do
    it 'touch the form' do
      field_a = fields(:field_a)
      field_b = fields(:field_b)
      form_a = forms(:form_a)
      expect {
        Field.delete_collection [field_a.id, field_b.id]
      }.to change { form_a.reload.updated_at }
    end
  end

  describe 'destroying options' do
    it 'update the options_count of the field' do
      option_a = options(:option_a)
      option_b = options(:option_b)
      field_a = fields(:field_a)
      field_b = fields(:field_b)
      expect {
        Option.delete_collection [option_a.id, option_b.id]
      }.to change { field_a.reload.options.count }.by -1
    end
  end
end