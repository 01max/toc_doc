# frozen_string_literal: true

RSpec.describe TocDoc::Profile::Organization do
  subject(:organization) do
    described_class.new(
      'id' => 42,
      'name' => 'Clinique du Parc',
      'partial' => true,
      'city' => 'Lyon'
    )
  end

  describe '#inspect' do
    it 'includes inherited and declared main_attrs' do
      expect(organization.inspect)
        .to include('@id=')
        .and include('@partial=')
        .and include('@name=')
    end

    it 'excludes undeclared attrs' do
      expect(organization.inspect).not_to include('@city=')
    end
  end

  describe '.main_attrs' do
    it 'merges parent attrs with the subclass declaration' do
      expect(described_class.main_attrs).to eq(%w[id partial name])
    end
  end
end
