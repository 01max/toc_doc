# frozen_string_literal: true

RSpec.describe TocDoc::Speciality do
  subject(:speciality) do
    described_class.new('value' => 228, 'slug' => 'homeopathe', 'name' => 'Homéopathe')
  end

  describe '#inspect' do
    it 'includes declared main_attrs' do
      expect(speciality.inspect).to include('@name=').and include('@slug=')
    end

    it 'excludes undeclared attrs' do
      expect(speciality.inspect).not_to include('@value=')
    end
  end

  describe 'dot-notation attribute access' do
    it 'exposes value' do
      expect(speciality.value).to eq(228)
    end

    it 'exposes slug' do
      expect(speciality.slug).to eq('homeopathe')
    end

    it 'exposes name' do
      expect(speciality.name).to eq('Homéopathe')
    end

    it 'supports bracket access' do
      expect(speciality['slug']).to eq('homeopathe')
    end

    it 'round-trips to a plain Hash via #to_h' do
      expect(speciality.to_h).to eq('value' => 228, 'slug' => 'homeopathe', 'name' => 'Homéopathe')
    end
  end
end
