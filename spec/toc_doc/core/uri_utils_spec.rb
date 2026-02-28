# frozen_string_literal: true

RSpec.describe TocDoc::UriUtils do
  subject(:obj) do
    Class.new { include TocDoc::UriUtils }.new
  end

  describe '#dashed_ids' do
    it 'returns a single ID as a string' do
      expect(obj.dashed_ids(42)).to eq('42')
    end

    it 'joins multiple IDs with dashes' do
      expect(obj.dashed_ids([1, 2, 3])).to eq('1-2-3')
    end

    it 'handles string IDs' do
      expect(obj.dashed_ids(%w[abc def])).to eq('abc-def')
    end

    it 'flattens nested arrays' do
      expect(obj.dashed_ids([[1, 2], [3]])).to eq('1-2-3')
    end

    it 'compacts nil values' do
      expect(obj.dashed_ids([1, nil, 3])).to eq('1-3')
    end

    it 'rejects empty strings' do
      expect(obj.dashed_ids([1, '', 3])).to eq('1-3')
    end

    it 'returns an empty string for an empty array' do
      expect(obj.dashed_ids([])).to eq('')
    end

    it 'returns an empty string for nil' do
      expect(obj.dashed_ids(nil)).to eq('')
    end

    it 'coerces non-string scalars to strings' do
      expect(obj.dashed_ids(99)).to eq('99')
    end
  end
end
