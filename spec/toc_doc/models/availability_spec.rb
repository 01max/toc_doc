# frozen_string_literal: true

RSpec.describe TocDoc::Availability do
  let(:slots) { ['2026-02-28T10:00:00.000+01:00', '2026-02-28T10:15:00.000+01:00'] }

  subject(:availability) do
    described_class.new('date' => '2026-02-28', 'slots' => slots)
  end

  describe '#date' do
    it 'returns a parsed Date object' do
      expect(availability.date).to eq(Date.new(2026, 2, 28))
    end
  end

  describe '#slots' do
    it 'returns an array of parsed DateTime objects' do
      expect(availability.slots).to all(be_a(DateTime))
      expect(availability.slots.first).to eq(DateTime.parse('2026-02-28T10:00:00.000+01:00'))
    end

    it 'returns an empty array when no slots key is present' do
      expect(described_class.new('date' => '2026-02-28').slots).to eq([])
    end
  end

  describe '#to_h' do
    it 'round-trips to a plain Hash' do
      expect(availability.to_h).to eq('date' => '2026-02-28', 'slots' => slots)
    end
  end

  describe 'inherited dot-notation access' do
    it 'still responds to arbitrary attributes via method_missing' do
      avail = described_class.new('date' => '2026-02-28', 'slots' => [], 'extra' => 'value')
      expect(avail.extra).to eq('value')
    end
  end
end
