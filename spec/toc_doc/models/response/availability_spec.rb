# frozen_string_literal: true

require 'json'

RSpec.describe TocDoc::Response::Availability do
  let(:raw_hash) { JSON.parse(fixture('availabilities.json')) }

  subject(:response) { described_class.new(raw_hash) }

  describe '#total' do
    it 'returns the total count' do
      expect(response.total).to eq(2)
    end
  end

  describe '#next_slot' do
    context 'when the next_slot key is present (no slots in loaded dates)' do
      it 'returns the next_slot value from the response' do
        r = described_class.new('total' => 0, 'next_slot' => '2026-03-24T09:00:00.000+01:00',
                                'availabilities' => [{ 'date' => '2026-03-04', 'slots' => [] }])
        expect(r.next_slot).to eq('2026-03-24T09:00:00.000+01:00')
      end
    end

    context 'when the next_slot key is absent and slots exist' do
      it 'returns the first slot of the first date that has one' do
        r = described_class.new(
          'total' => 1,
          'availabilities' => [
            { 'date' => '2026-03-04', 'slots' => [] },
            { 'date' => '2026-03-09', 'slots' => ['2026-03-09T14:50:00.000+01:00'] }
          ]
        )
        expect(r.next_slot).to eq('2026-03-09T14:50:00.000+01:00')
      end
    end

    context 'when the next_slot key is absent and no slots exist' do
      it 'returns nil' do
        expect(described_class.new('total' => 0, 'availabilities' => []).next_slot).to be_nil
      end
    end

    it 'returns the next_slot value from the fixture' do
      expect(response.next_slot).to eq('2026-02-28T10:00:00.000+01:00')
    end
  end

  describe '#availabilities' do
    it 'returns an array of TocDoc::Availability objects' do
      expect(response.availabilities).to all(be_a(TocDoc::Availability))
    end

    it 'has the correct length' do
      expect(response.availabilities.length).to eq(2)
    end

    it 'correctly maps date on the first entry' do
      expect(response.availabilities.first.date).to eq('2026-02-28')
    end

    it 'correctly maps slots on the first entry' do
      expect(response.availabilities.first.slots.length).to eq(3)
    end

    it 'correctly maps the second entry' do
      second = response.availabilities.last
      expect(second.date).to eq('2026-03-01')
      expect(second.slots.length).to eq(2)
    end

    it 'returns an empty array when missing' do
      expect(described_class.new('total' => 0).availabilities).to eq([])
    end

    it 'memoises the result' do
      expect(response.availabilities).to equal(response.availabilities)
    end
  end

  describe '#to_h' do
    it 'round-trips to a plain Hash' do
      expect(response.to_h).to eq(raw_hash)
    end

    it 'includes availabilities as plain Hashes (not objects)' do
      avails = response.to_h['availabilities']
      expect(avails).to all(be_a(Hash))
    end
  end

  describe 'dot-notation access for extra fields' do
    it 'exposes unknown top-level fields via method_missing' do
      r = described_class.new(raw_hash.merge('custom_field' => 'hello'))
      expect(r.custom_field).to eq('hello')
    end
  end
end
