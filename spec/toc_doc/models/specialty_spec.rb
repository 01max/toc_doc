# frozen_string_literal: true

RSpec.describe TocDoc::Specialty do
  subject(:specialty) do
    described_class.new('value' => 228, 'slug' => 'homeopathe', 'name' => 'Homéopathe')
  end

  describe 'dot-notation attribute access' do
    it 'exposes value' do
      expect(specialty.value).to eq(228)
    end

    it 'exposes slug' do
      expect(specialty.slug).to eq('homeopathe')
    end

    it 'exposes name' do
      expect(specialty.name).to eq('Homéopathe')
    end

    it 'supports bracket access' do
      expect(specialty['slug']).to eq('homeopathe')
    end

    it 'round-trips to a plain Hash via #to_h' do
      expect(specialty.to_h).to eq('value' => 228, 'slug' => 'homeopathe', 'name' => 'Homéopathe')
    end
  end
end
