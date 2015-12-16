require 'spec_helper'

describe 'AwesomeDelete' do

  before(:all) do
      self.class.fixtures :forms, :fields
    end

  it 'test' do
    form = Form.create title: 'haha'
    expect(form.title).to eq 'haha'
  end

  it 'decrements the forms count' do
    form_a = forms(:form_a)
    expect {
      Form.delete_collection [form_a.id]
    }.to change { Form.count }.by -1
  end
end