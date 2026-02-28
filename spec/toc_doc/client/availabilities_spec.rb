# frozen_string_literal: true

RSpec.describe TocDoc::Client::Availabilities do
  let(:client) { TocDoc::Client.new }

  let(:base_url) { 'https://www.doctolib.fr/availabilities.json' }
  let(:fixture_body) { fixture('availabilities.json') }

  let(:default_query) do
    {
      visit_motive_ids: '7767829',
      agenda_ids: '1101600',
      start_date: '2026-02-28',
      limit: '5'
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

  describe '#availabilities' do
    before { stub_availabilities }

    it 'is callable on the client' do
      expect(client).to respond_to(:availabilities)
    end

    it 'calls the correct endpoint' do
      client.availabilities(
        visit_motive_ids: 7_767_829,
        agenda_ids: 1_101_600,
        start_date: Date.new(2026, 2, 28)
      )
      expect(a_request(:get, base_url).with(query: default_query)).to have_been_made.once
    end

    it 'returns parsed JSON with top-level keys' do
      result = client.availabilities(
        visit_motive_ids: 7_767_829,
        agenda_ids: 1_101_600,
        start_date: Date.new(2026, 2, 28)
      )

      expect(result).to be_a(Hash)
      expect(result['total']).to eq(2)
      expect(result['next_slot']).to eq('2026-02-28T10:00:00.000+01:00')
    end

    it 'returns an array of availabilities' do
      result = client.availabilities(
        visit_motive_ids: 7_767_829,
        agenda_ids: 1_101_600,
        start_date: Date.new(2026, 2, 28)
      )

      avails = result['availabilities']
      expect(avails).to be_an(Array)
      expect(avails.length).to eq(2)
      expect(avails.first['date']).to eq('2026-02-28')
      expect(avails.first['slots']).to be_an(Array)
      expect(avails.first['slots'].length).to eq(3)
    end
  end

  describe 'parameter serialization' do
    it 'joins multiple visit_motive_ids with dashes' do
      stub_request(:get, base_url)
        .with(query: hash_including(visit_motive_ids: '111-222-333'))
        .to_return(status: 200, body: fixture_body, headers: { 'Content-Type' => 'application/json' })

      client.availabilities(
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

      client.availabilities(
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

      client.availabilities(
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
    it 'uses per_page as the default limit' do
      stub_request(:get, base_url)
        .with(query: hash_including(limit: client.per_page.to_s))
        .to_return(status: 200, body: fixture_body, headers: { 'Content-Type' => 'application/json' })

      client.availabilities(
        visit_motive_ids: 7_767_829,
        agenda_ids: 1_101_600,
        start_date: Date.new(2026, 2, 28)
      )

      expect(
        a_request(:get, base_url).with(query: hash_including(limit: client.per_page.to_s))
      ).to have_been_made.once
    end

    it 'accepts a custom limit' do
      stub_request(:get, base_url)
        .with(query: hash_including(limit: '10'))
        .to_return(status: 200, body: fixture_body, headers: { 'Content-Type' => 'application/json' })

      client.availabilities(
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
    it 'delegates TocDoc.availabilities to the memoized client' do
      TocDoc.reset!
      stub_availabilities

      result = TocDoc.availabilities(
        visit_motive_ids: 7_767_829,
        agenda_ids: 1_101_600,
        start_date: Date.new(2026, 2, 28)
      )

      expect(result['total']).to eq(2)
    ensure
      TocDoc.reset!
    end
  end
end
