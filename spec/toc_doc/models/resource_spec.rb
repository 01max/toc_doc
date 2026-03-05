# frozen_string_literal: true

RSpec.describe TocDoc::Resource do
  subject(:resource) { described_class.new('date' => '2026-02-28', 'total' => 5) }

  describe '#[]' do
    it 'reads attributes by string key' do
      expect(resource['date']).to eq('2026-02-28')
    end

    it 'reads attributes by symbol key' do
      expect(resource[:date]).to eq('2026-02-28')
    end

    it 'returns nil for unknown keys' do
      expect(resource['unknown']).to be_nil
    end
  end

  describe '#[]=' do
    it 'sets an attribute by string key' do
      resource['new_key'] = 42
      expect(resource['new_key']).to eq(42)
    end

    it 'sets an attribute by symbol key' do
      resource[:new_key] = 42
      expect(resource[:new_key]).to eq(42)
    end
  end

  describe 'dot-notation access' do
    it 'exposes known attributes as methods' do
      expect(resource.date).to eq('2026-02-28')
      expect(resource.total).to eq(5)
    end

    it 'raises NoMethodError for unknown attributes' do
      expect { resource.nonexistent }.to raise_error(NoMethodError)
    end
  end

  describe '#respond_to_missing?' do
    it 'returns true for known attribute names' do
      expect(resource).to respond_to(:date)
    end

    it 'returns false for unknown attribute names' do
      expect(resource).not_to respond_to(:nonexistent)
    end
  end

  describe '#to_h' do
    it 'returns a Hash copy of the attributes' do
      expect(resource.to_h).to eq('date' => '2026-02-28', 'total' => 5)
    end

    it 'returns a copy (not the internal hash)' do
      h = resource.to_h
      h['date'] = 'changed'
      expect(resource.date).to eq('2026-02-28')
    end
  end

  describe '#==' do
    it 'equals another Resource with the same attributes' do
      other = described_class.new('date' => '2026-02-28', 'total' => 5)
      expect(resource).to eq(other)
    end

    it 'equals a Hash with equivalent string-keyed data' do
      expect(resource).to eq('date' => '2026-02-28', 'total' => 5)
    end

    it 'accepts symbol-keyed Hash for comparison' do
      expect(resource).to eq(date: '2026-02-28', total: 5)
    end

    it 'does not equal a different Resource' do
      other = described_class.new('date' => '2099-01-01')
      expect(resource).not_to eq(other)
    end

    it 'does not equal non-Resource/non-Hash objects' do
      expect(resource == 'a string').to be false
      expect(resource == 42).to be false
    end
  end

  describe 'symbol keys in constructor' do
    it 'normalises symbol keys to strings' do
      r = described_class.new(date: '2026-02-28')
      expect(r.date).to eq('2026-02-28')
      expect(r['date']).to eq('2026-02-28')
    end
  end
end
