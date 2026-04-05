# frozen_string_literal: true

require 'toc_doc/http/middleware/cache'
require 'toc_doc/cache/memory_store'

RSpec.describe TocDoc::Middleware::Cache do
  let(:store) { TocDoc::Cache::MemoryStore.new }
  let(:base_url) { 'https://www.doctolib.fr' }

  let(:connection) do
    Faraday.new(base_url) do |builder|
      builder.use described_class, store: store, ttl: 300
      builder.response :json, content_type: /\bjson$/
      builder.adapter Faraday.default_adapter
    end
  end

  describe 'GET request — cache miss then cache hit' do
    before do
      stub_request(:get, "#{base_url}/availabilities.json")
        .to_return(status: 200, body: '{"total":5}', headers: { 'Content-Type' => 'application/json' })
    end

    it 'returns a 200 response on the first call (miss)' do
      response = connection.get('/availabilities.json')
      expect(response.status).to eq(200)
    end

    it 'calls the adapter exactly once when the second request hits the cache' do
      connection.get('/availabilities.json')
      connection.get('/availabilities.json')

      expect(a_request(:get, "#{base_url}/availabilities.json")).to have_been_made.once
    end

    it 'returns the same parsed body on the second call (hit)' do
      first  = connection.get('/availabilities.json').body
      second = connection.get('/availabilities.json').body
      expect(second).to eq(first)
    end
  end

  describe 'POST requests' do
    before do
      stub_request(:post, "#{base_url}/appointments")
        .to_return(status: 200, body: '{}', headers: { 'Content-Type' => 'application/json' })
    end

    it 'are not cached and always hit the adapter' do
      connection.post('/appointments')
      connection.post('/appointments')
      expect(a_request(:post, "#{base_url}/appointments")).to have_been_made.twice
    end
  end

  describe 'non-200 responses' do
    before do
      stub_request(:get, "#{base_url}/missing")
        .to_return(status: 404, body: '', headers: {})
    end

    it 'are not cached' do
      connection.get('/missing')
      connection.get('/missing')
      expect(a_request(:get, "#{base_url}/missing")).to have_been_made.twice
    end
  end

  describe 'sorted query parameters' do
    before do
      stub_request(:get, "#{base_url}/search")
        .with(query: hash_including({}))
        .to_return(status: 200, body: '{}', headers: { 'Content-Type' => 'application/json' })
    end

    it 'treats requests with the same params in different order as identical' do
      connection.get('/search', z: '1', a: '2')
      connection.get('/search', a: '2', z: '1')
      expect(a_request(:get, "#{base_url}/search").with(query: hash_including({}))).to have_been_made.once
    end
  end

  describe 'TTL expiration' do
    let(:short_ttl_connection) do
      Faraday.new(base_url) do |builder|
        builder.use described_class, store: store, ttl: 0.01
        builder.response :json, content_type: /\bjson$/
        builder.adapter Faraday.default_adapter
      end
    end

    before do
      stub_request(:get, "#{base_url}/ttl")
        .to_return(status: 200, body: '{}', headers: { 'Content-Type' => 'application/json' })
    end

    it 'fetches from the adapter again after the TTL expires' do
      short_ttl_connection.get('/ttl')
      sleep(0.05)
      short_ttl_connection.get('/ttl')
      expect(a_request(:get, "#{base_url}/ttl")).to have_been_made.twice
    end
  end
end
