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
        r = described_class.new({ 'total' => 0, 'next_slot' => '2026-03-24T09:00:00.000+01:00',
                                  'availabilities' => [{ 'date' => '2026-03-04', 'slots' => [] }] })
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
        expect(described_class.new({ 'total' => 0, 'availabilities' => [] }).next_slot).to be_nil
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
      expect(described_class.new({ 'total' => 0 }).to_a).to eq([])
    end

    it 'returns the same Availability objects on repeated calls (memoization)' do
      first_call  = response.to_a
      second_call = response.to_a
      first_call.zip(second_call).each do |a, b|
        expect(a).to equal(b)
      end
    end

    it 'returns a fresh result after merge_page! (cache invalidation)' do
      first_call = response.to_a
      response.merge_page!({ 'total' => 0, 'availabilities' => [] })
      second_call = response.to_a
      expect(first_call).not_to equal(second_call)
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

  describe '#merge_page!' do
    it 'appends availabilities from the new page' do
      page1 = { 'total' => 3,
                'availabilities' => [{ 'date' => '2026-03-01', 'slots' => ['2026-03-01T09:00:00.000+01:00'] }] }
      page2 = { 'total' => 2,
                'availabilities' => [{ 'date' => '2026-03-02', 'slots' => ['2026-03-02T10:00:00.000+01:00'] }] }
      collection = described_class.new(page1)
      collection.merge_page!(page2)
      expect(collection.to_a.length).to eq(2)
      expect(collection.to_a.map(&:date)).to eq([Date.new(2026, 3, 1), Date.new(2026, 3, 2)])
    end

    it 'sums totals from both pages' do
      page1 = { 'total' => 3, 'availabilities' => [] }
      page2 = { 'total' => 2, 'availabilities' => [] }
      collection = described_class.new(page1)
      collection.merge_page!(page2)
      expect(collection.total).to eq(5)
    end

    it 'returns self' do
      collection = described_class.new({ 'total' => 1, 'availabilities' => [] })
      result = collection.merge_page!({ 'total' => 0, 'availabilities' => [] })
      expect(result).to be(collection)
    end

    it 'handles missing availabilities key in page_data' do
      collection = described_class.new({ 'total' => 2,
                                         'availabilities' => [{ 'date' => '2026-03-01',
                                                                'slots' => ['2026-03-01T09:00:00.000+01:00'] }] })
      collection.merge_page!({ 'total' => 1 })
      expect(collection.to_a.length).to eq(1)
      expect(collection.total).to eq(3)
    end

    it 'handles missing total key in page_data' do
      collection = described_class.new({ 'total' => 2, 'availabilities' => [] })
      collection.merge_page!({ 'availabilities' => [] })
      expect(collection.total).to eq(2)
    end
  end

  describe '#more?' do
    it 'returns true when next_slot is present' do
      r = described_class.new({ 'total' => 0, 'next_slot' => '2026-03-24T09:00:00.000+01:00',
                                'availabilities' => [] })
      expect(r.more?).to be(true)
    end

    it 'returns false when next_slot is absent' do
      expect(response.more?).to be(false)
    end
  end

  describe '#load_next!' do
    let(:base_url) { 'https://www.doctolib.fr/availabilities.json' }
    let(:page1_data) { JSON.parse(fixture('availabilities_page1.json')) }
    let(:page2_data) { JSON.parse(fixture('availabilities_page2.json')) }

    context 'when no client is provided' do
      it 'raises TocDoc::Error' do
        collection = described_class.new(page1_data)
        expect { collection.load_next! }.to raise_error(TocDoc::Error, /No client available/)
      end
    end

    context 'when more? is false' do
      it 'raises StopIteration' do
        client = TocDoc.client
        collection = described_class.new(page2_data, client: client)
        expect { collection.load_next! }.to raise_error(StopIteration)
      end
    end

    context 'when more? is true and a client is provided' do
      it 'fetches the next page and merges it' do
        stub_request(:get, base_url)
          .with(query: hash_including(start_date: '2026-03-12'))
          .to_return(status: 200, body: fixture('availabilities_page2.json'),
                     headers: { 'Content-Type' => 'application/json' })

        client = TocDoc.client
        collection = described_class.new(
          page1_data,
          query: { visit_motive_ids: '7767829', agenda_ids: '1101600', limit: 15 },
          path: '/availabilities.json',
          client: client
        )

        result = collection.load_next!
        expect(result).to be(collection)
        expect(collection.more?).to be(false)
        expect(collection.total).to eq(3)
      end
    end

    context 'backward compatibility' do
      it 'still works without client keyword (defaults to nil)' do
        collection = described_class.new(page2_data)
        expect(collection).to be_a(described_class)
      end
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
    before do
      stub_availabilities
    end

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

    context 'with pagination_depth: 0' do
      around do |example|
        original = TocDoc.pagination_depth
        TocDoc.pagination_depth = 0
        example.run
      ensure
        TocDoc.pagination_depth = original
      end

      it 'does not follow next_slot even when present' do
        stub_page('2026-03-01', page1_body)

        result = TocDoc::Availability.where(
          visit_motive_ids: 7_767_829,
          agenda_ids: 1_101_600,
          start_date: Date.new(2026, 3, 1)
        )

        expect(a_request(:get, base_url).with(query: hash_including(start_date: '2026-03-01')))
          .to have_been_made.once
        expect(result.more?).to be(true)
        expect(result.total).to eq(0)
      end
    end

    context 'with pagination_depth: 2' do
      around do |example|
        original = TocDoc.pagination_depth
        TocDoc.pagination_depth = 2
        example.run
      ensure
        TocDoc.pagination_depth = original
      end

      it 'follows two next_slot hops and concatenates three pages' do
        page3_body = fixture('availabilities_page3.json')
        # page1: next_slot → 2026-03-12
        stub_page('2026-03-01', page1_body)
        # page2: we need a page2 with next_slot to trigger second hop
        page2_with_next = {
          'total' => 3,
          'next_slot' => '2026-03-20T10:00:00.000+01:00',
          'availabilities' => [
            { 'date' => '2026-03-12', 'slots' => ['2026-03-12T09:00:00.000+01:00'] }
          ]
        }.to_json
        stub_page('2026-03-12', page2_with_next)
        stub_page('2026-03-20', page3_body)

        result = TocDoc::Availability.where(
          visit_motive_ids: 7_767_829,
          agenda_ids: 1_101_600,
          start_date: Date.new(2026, 3, 1)
        )

        expect(result.to_a.length).to eq(2)
        expect(result.to_a.map(&:date)).to eq([Date.new(2026, 3, 12), Date.new(2026, 3, 20)])
        expect(result.more?).to be(false)
      end
    end
  end
end
