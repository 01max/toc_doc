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

    it 'returns a copy (mutations do not affect the resource)' do
      h = resource.to_h
      h['date'] = 'changed'
      expect(resource.date).to eq('2026-02-28')
    end

    context 'when an attribute value is a nested Resource' do
      let(:inner) { described_class.new('name' => 'inner') }
      let(:outer) { described_class.new('child' => inner, 'count' => 1) }

      it 'recursively converts the nested Resource to a plain Hash' do
        expect(outer.to_h['child']).to eq('name' => 'inner')
      end

      it 'does not return Resource instances in the output' do
        expect(outer.to_h.values).to all(satisfy { |v| !v.is_a?(described_class) })
      end
    end

    context 'when an attribute value is an Array containing Resources' do
      let(:r1) { described_class.new('x' => 1) }
      let(:r2) { described_class.new('x' => 2) }
      let(:resource_with_array) { described_class.new('items' => [r1, r2, 'plain']) }

      it 'converts Resource elements to plain Hashes' do
        expect(resource_with_array.to_h['items']).to eq([{ 'x' => 1 }, { 'x' => 2 }, 'plain'])
      end
    end

    context 'when an attribute value is a Hash containing a Resource' do
      let(:inner) { described_class.new('val' => 42) }
      let(:resource_with_hash) { described_class.new('meta' => { 'nested' => inner }) }

      it 'recursively converts Resource values inside Hashes' do
        expect(resource_with_hash.to_h['meta']).to eq('nested' => { 'val' => 42 })
      end
    end
  end

  describe '#to_json' do
    it 'returns a String' do
      expect(resource.to_json).to be_a(String)
    end

    it 'round-trips through JSON.parse back to the plain hash' do
      expect(JSON.parse(resource.to_json)).to eq(resource.to_h)
    end

    context 'when the resource contains nested Resources' do
      let(:inner) { described_class.new('name' => 'inner') }
      let(:outer) { described_class.new('child' => inner) }

      it 'serializes nested Resources correctly' do
        parsed = JSON.parse(outer.to_json)
        expect(parsed['child']).to eq('name' => 'inner')
      end
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

  describe '#attribute_names' do
    it 'returns the attribute keys as strings' do
      expect(resource.attribute_names).to eq(%w[date total])
    end

    it 'reflects keys added via []=' do
      resource[:new_key] = 99
      expect(resource.attribute_names).to include('new_key')
    end
  end

  describe 'singleton method definition on first dot-notation access' do
    it 'defines a real method after first access so #method works' do
      resource.date
      expect(resource.method(:date)).to be_a(Method)
    end

    it 'subsequent calls return the correct value' do
      resource.date
      expect(resource.date).to eq('2026-02-28')
    end

    it 'reflects mutations via []= through the defined singleton method' do
      resource.date
      resource[:date] = '2099-01-01'
      expect(resource.date).to eq('2099-01-01')
    end
  end
end
