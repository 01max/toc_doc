# frozen_string_literal: true

require 'json'

RSpec.describe TocDoc::Availability::Collection do
  let(:raw_hash) { JSON.parse(fixture('availabilities.json')) }

  subject(:response) { described_class.new(raw_hash) }

  describe '#total' do
    it 'returns the total count' do
      expect(response.total).to eq(5)
    end
  end

  describe '#next_slot' do
    context 'when the next_slot key is present (no slots in loaded dates)' do
      it 'returns the next_slot value from the response' do
        r = described_class.new({'total' => 0, 'next_slot' => '2026-03-24T09:00:00.000+01:00',
                                 'availabilities' => [{ 'date' => '2026-03-04', 'slots' => [] }]})
        expect(r.next_slot).to eq('2026-03-24T09:00:00.000+01:00')
      end
    end

    context 'when the next_slot key is absent and slots exist' do
      it 'returns the first slot of the first date that has one' do
        r = described_class.new({
          'total' => 1,
          'availabilities' => [
            { 'date' => '2026-03-04', 'slots' => [] },
            { 'date' => '2026-03-09', 'slots' => ['2026-03-09T14:50:00.000+01:00'] }
          ]
        })
        expect(r.next_slot).to eq('2026-03-09T14:50:00.000+01:00')
      end
    end

    context 'when the next_slot key is absent and no slots exist' do
      it 'returns nil' do
        expect(described_class.new({'total' => 0, 'availabilities' => []}).next_slot).to be_nil
      end
    end

    it 'infers next_slot from the first available slot in the fixture' do
      expect(response.next_slot).to eq('2026-02-28T10:00:00.000+01:00')
    end
  end

  describe '#each / #to_a' do
    it 'returns an array of TocDoc::Availability objects' do
      expect(response.to_a).to all(be_a(TocDoc::Availability))
    end

    it 'has the correct length' do
      expect(response.to_a.length).to eq(2)
    end

    it 'correctly maps date on the first entry' do
      expect(response.to_a.first.date).to eq(Date.new(2026, 2, 28))
    end

    it 'correctly maps slots on the first entry' do
      expect(response.to_a.first.slots.length).to eq(3)
    end

    it 'correctly maps the second entry' do
      second = response.to_a.last
      expect(second.date).to eq(Date.new(2026, 3, 1))
      expect(second.slots.length).to eq(2)
    end

    it 'excludes dates with no slots' do
      r = described_class.new({
        'total' => 1,
        'availabilities' => [
          { 'date' => '2026-03-04', 'slots' => [] },
          { 'date' => '2026-03-09', 'slots' => ['2026-03-09T14:50:00.000+01:00'] }
        ]
      })
      expect(r.to_a.length).to eq(1)
      expect(r.to_a.first.date).to eq(Date.new(2026, 3, 9))
    end

    it 'returns an empty array when missing' do
      expect(described_class.new({'total' => 0}).to_a).to eq([])
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

  describe '#raw_availabilities' do
    it 'includes entries with empty slots' do
      r = described_class.new({
        'total' => 1,
        'availabilities' => [
          { 'date' => '2026-03-04', 'slots' => [] },
          { 'date' => '2026-03-09', 'slots' => ['2026-03-09T14:50:00.000+01:00'] }
        ]
      })
      expect(r.raw_availabilities.length).to eq(2)
      expect(r.raw_availabilities.first.date).to eq(Date.new(2026, 3, 4))
    end
  end
end

RSpec.describe TocDoc::Availability do
  let(:base_url) { 'https://www.doctolib.fr/availabilities.json' }
  let(:fixture_body) { fixture('availabilities.json') }

  let(:default_query) do
    {
      visit_motive_ids: '7767829',
      agenda_ids: '1101600',
      start_date: '2026-02-28',
      limit: TocDoc::Default::PER_PAGE.to_s
    }
  end

  def stub_availabilities(query = {})
    stub_request(:get, base_url)
      .with(query: default_query.merge(query))
      .to_return(
        status: 200,
        body: fixture_body,
        headers: { 'Content-Type' => 'application/json' }
      )
  end

  describe '.where' do
    before { stub_availabilities }

    it 'calls the correct endpoint' do
      TocDoc::Availability.where(
        visit_motive_ids: 7_767_829,
        agenda_ids: 1_101_600,
        start_date: Date.new(2026, 2, 28)
      )
      expect(a_request(:get, base_url).with(query: default_query)).to have_been_made.once
    end

    it 'returns a Collection with top-level fields' do
      result = TocDoc::Availability.where(
        visit_motive_ids: 7_767_829,
        agenda_ids: 1_101_600,
        start_date: Date.new(2026, 2, 28)
      )

      expect(result).to be_a(TocDoc::Availability::Collection)
      expect(result.total).to eq(5)
      expect(result.next_slot).to eq('2026-02-28T10:00:00.000+01:00')
    end

    it 'is enumerable over Availability objects with slots' do
      result = TocDoc::Availability.where(
        visit_motive_ids: 7_767_829,
        agenda_ids: 1_101_600,
        start_date: Date.new(2026, 2, 28)
      )

      avails = result.to_a
      expect(avails).to be_an(Array)
      expect(avails.length).to eq(2)
      expect(avails).to all(be_a(TocDoc::Availability))
      expect(avails.first.date).to eq(Date.new(2026, 2, 28))
      expect(avails.first.slots).to be_an(Array)
      expect(avails.first.slots.length).to eq(3)
    end
  end

  describe 'parameter serialization' do
    it 'joins multiple visit_motive_ids with dashes' do
      stub_request(:get, base_url)
        .with(query: hash_including(visit_motive_ids: '111-222-333'))
        .to_return(status: 200, body: fixture_body, headers: { 'Content-Type' => 'application/json' })

      TocDoc::Availability.where(
        visit_motive_ids: [111, 222, 333],
        agenda_ids: 1_101_600,
        start_date: Date.new(2026, 2, 28)
      )

      expect(
        a_request(:get, base_url).with(query: hash_including(visit_motive_ids: '111-222-333'))
      ).to have_been_made.once
    end

    it 'joins multiple agenda_ids with dashes' do
      stub_request(:get, base_url)
        .with(query: hash_including(agenda_ids: '100-200'))
        .to_return(status: 200, body: fixture_body, headers: { 'Content-Type' => 'application/json' })

      TocDoc::Availability.where(
        visit_motive_ids: 7_767_829,
        agenda_ids: [100, 200],
        start_date: Date.new(2026, 2, 28)
      )

      expect(
        a_request(:get, base_url).with(query: hash_including(agenda_ids: '100-200'))
      ).to have_been_made.once
    end

    it 'forwards extra keyword options as query params' do
      stub_request(:get, base_url)
        .with(query: hash_including(practice_ids: '377272', telehealth: 'false'))
        .to_return(status: 200, body: fixture_body, headers: { 'Content-Type' => 'application/json' })

      TocDoc::Availability.where(
        visit_motive_ids: 7_767_829,
        agenda_ids: 1_101_600,
        start_date: Date.new(2026, 2, 28),
        practice_ids: 377_272,
        telehealth: false
      )

      expect(
        a_request(:get, base_url).with(query: hash_including(practice_ids: '377272', telehealth: 'false'))
      ).to have_been_made.once
    end
  end

  describe 'default parameter values' do
    it 'uses TocDoc.per_page as the default limit' do
      stub_request(:get, base_url)
        .with(query: hash_including(limit: TocDoc.per_page.to_s))
        .to_return(status: 200, body: fixture_body, headers: { 'Content-Type' => 'application/json' })

      TocDoc::Availability.where(
        visit_motive_ids: 7_767_829,
        agenda_ids: 1_101_600,
        start_date: Date.new(2026, 2, 28)
      )

      expect(
        a_request(:get, base_url).with(query: hash_including(limit: TocDoc.per_page.to_s))
      ).to have_been_made.once
    end

    it 'accepts a custom limit' do
      stub_request(:get, base_url)
        .with(query: hash_including(limit: '10'))
        .to_return(status: 200, body: fixture_body, headers: { 'Content-Type' => 'application/json' })

      TocDoc::Availability.where(
        visit_motive_ids: 7_767_829,
        agenda_ids: 1_101_600,
        start_date: Date.new(2026, 2, 28),
        limit: 10
      )

      expect(
        a_request(:get, base_url).with(query: hash_including(limit: '10'))
      ).to have_been_made.once
    end
  end

  describe 'module-level delegation' do
    it 'TocDoc.availabilities delegates to Availability.where' do
      TocDoc.reset!
      stub_availabilities

      result = TocDoc.availabilities(
        visit_motive_ids: 7_767_829,
        agenda_ids: 1_101_600,
        start_date: Date.new(2026, 2, 28)
      )

      expect(result).to be_a(TocDoc::Availability::Collection)
      expect(result.total).to eq(5)
    ensure
      TocDoc.reset!
    end
  end

  describe 'pagination' do
    let(:page1_body) { fixture('availabilities_page1.json') }
    let(:page2_body) { fixture('availabilities_page2.json') }

    # page 1: start_date 2026-03-01, has next_slot "2026-03-12T09:00:00.000+01:00"
    #         → triggers a silent follow-up fetch from 2026-03-12
    # page 2: start_date 2026-03-12, no next_slot → stops
    def stub_page(start_date, body)
      stub_request(:get, base_url)
        .with(query: hash_including(start_date: start_date))
        .to_return(status: 200, body: body, headers: { 'Content-Type' => 'application/json' })
    end

    context 'when next_slot is present' do
      it 'silently fetches from the next_slot date and concatenates availabilities' do
        stub_page('2026-03-01', page1_body)
        stub_page('2026-03-12', page2_body)

        result = TocDoc::Availability.where(
          visit_motive_ids: 7_767_829,
          agenda_ids: 1_101_600,
          start_date: Date.new(2026, 3, 1)
        )

        expect(result.to_a.length).to eq(1)
        expect(result.map(&:date)).to eq([Date.new(2026, 3, 12)])
      end

      it 'sums totals across pages' do
        stub_page('2026-03-01', page1_body)
        stub_page('2026-03-12', page2_body)

        result = TocDoc::Availability.where(
          visit_motive_ids: 7_767_829,
          agenda_ids: 1_101_600,
          start_date: Date.new(2026, 3, 1)
        )

        expect(result.total).to eq(3) # 0 + 3
      end

      it 'exposes the first available slot via next_slot after merging' do
        stub_page('2026-03-01', page1_body)
        stub_page('2026-03-12', page2_body)

        result = TocDoc::Availability.where(
          visit_motive_ids: 7_767_829,
          agenda_ids: 1_101_600,
          start_date: Date.new(2026, 3, 1)
        )

        expect(result.next_slot).to eq('2026-03-12T09:00:00.000+01:00')
      end
    end

    context 'when next_slot is absent' do
      it 'makes only one request and returns the page as-is' do
        stub_page('2026-03-01', page2_body)

        result = TocDoc::Availability.where(
          visit_motive_ids: 7_767_829,
          agenda_ids: 1_101_600,
          start_date: Date.new(2026, 3, 1)
        )

        expect(a_request(:get, base_url).with(query: hash_including(start_date: '2026-03-01')))
          .to have_been_made.once
        expect(result.to_a.length).to eq(1)
      end
    end
  end
end
