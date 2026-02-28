# frozen_string_literal: true

require 'toc_doc/connection'

RSpec.describe TocDoc::Connection do
  # Build a minimal anonymous class that mixes in both Configurable and
  # Connection so we can test the module in isolation.
  let(:client_class) do
    Class.new do
      include TocDoc::Configurable
      include TocDoc::Connection
    end
  end

  # Faraday test stubs shared across all HTTP-level examples.
  let(:stubs) { Faraday::Adapter::Test::Stubs.new }

  subject(:client) do
    instance = client_class.new
    instance.reset!
    # Replace the middleware stack with a test adapter so requests never hit
    # the network and VCR/WebMock are not involved.
    instance.middleware = Faraday::RackBuilder.new { |b| b.adapter :test, stubs }
    instance
  end

  describe '#agent' do
    it 'returns a Faraday::Connection' do
      expect(client.send(:agent)).to be_a(Faraday::Connection)
    end

    it 'is memoized' do
      expect(client.send(:agent)).to be(client.send(:agent))
    end

    it 'sets Accept header from default_media_type' do
      expect(client.send(:agent).headers['Accept']).to eq(TocDoc::Default::MEDIA_TYPE)
    end

    it 'sets Content-Type header from default_media_type' do
      expect(client.send(:agent).headers['Content-Type']).to eq(TocDoc::Default::MEDIA_TYPE)
    end

    it 'sets User-Agent header' do
      expect(client.send(:agent).headers['User-Agent']).to eq(TocDoc::Default::USER_AGENT)
    end
  end

  describe '#get' do
    it 'issues a GET request and exposes last_response' do
      stubs.get('/path') { [200, {}, '{}'] }

      client.send(:get, '/path')

      expect(client.last_response.status).to eq(200)
    end

    it 'forwards query params to the request URL' do
      stubs.get('/search') { [200, {}, '{}'] }

      client.send(:get, '/search', q: 'flu')

      expect(client.last_response.status).to eq(200)
    end
  end

  describe '#post' do
    it 'issues a POST request and exposes last_response' do
      stubs.post('/appointments') { [201, {}, '{}'] }

      client.send(:post, '/appointments', '{"name":"test"}')

      expect(client.last_response.status).to eq(201)
    end
  end

  describe '#put' do
    it 'issues a PUT request and exposes last_response' do
      stubs.put('/appointments/1') { [200, {}, '{}'] }

      client.send(:put, '/appointments/1', '{}')

      expect(client.last_response.status).to eq(200)
    end
  end

  describe '#patch' do
    it 'issues a PATCH request and exposes last_response' do
      stubs.patch('/appointments/1') { [200, {}, '{}'] }

      client.send(:patch, '/appointments/1', '{}')

      expect(client.last_response.status).to eq(200)
    end
  end

  describe '#delete' do
    it 'issues a DELETE request and exposes last_response' do
      stubs.delete('/appointments/1') { [204, {}, ''] }

      client.send(:delete, '/appointments/1')

      expect(client.last_response.status).to eq(204)
    end
  end

  describe '#head' do
    it 'issues a HEAD request and exposes last_response' do
      stubs.head('/path') { [200, {}, ''] }

      client.send(:head, '/path')

      expect(client.last_response.status).to eq(200)
    end
  end

  describe '#boolean_from_response' do
    it 'returns true for a 200 response' do
      stubs.get('/exists') { [200, {}, '{}'] }

      expect(client.send(:boolean_from_response, :get, '/exists')).to be(true)
    end

    it 'returns true for any 2xx response' do
      stubs.get('/no-content') { [204, {}, ''] }

      expect(client.send(:boolean_from_response, :get, '/no-content')).to be(true)
    end

    it 'returns false for a 404 response' do
      stubs.get('/missing') { [404, {}, '{}'] }

      expect(client.send(:boolean_from_response, :get, '/missing')).to be(false)
    end

    it 'returns false for other non-2xx responses' do
      stubs.get('/error') { [422, {}, '{}'] }

      expect(client.send(:boolean_from_response, :get, '/error')).to be(false)
    end
  end

  describe '#parse_query_and_convenience_headers' do
    it 'returns two empty hashes given nil' do
      query, headers = client.send(:parse_query_and_convenience_headers, nil)

      expect(query).to eq({})
      expect(headers).to eq({})
    end

    it 'returns two empty hashes given an empty hash' do
      query, headers = client.send(:parse_query_and_convenience_headers, {})

      expect(query).to eq({})
      expect(headers).to eq({})
    end

    it 'treats top-level keys as query params when no :query key is present' do
      query, headers = client.send(:parse_query_and_convenience_headers, { page: 2, limit: 10 })

      expect(query).to eq({ page: 2, limit: 10 })
      expect(headers).to eq({})
    end

    it 'extracts the :query key as query params' do
      query, headers = client.send(:parse_query_and_convenience_headers,
                                   { query: { start_date: '2026-01-01' } })

      expect(query).to eq({ start_date: '2026-01-01' })
      expect(headers).to eq({})
    end

    it 'extracts the :headers key as request headers' do
      query, headers = client.send(:parse_query_and_convenience_headers,
                                   { headers: { 'X-Token' => 'abc' } })

      expect(query).to eq({})
      expect(headers).to eq({ 'X-Token' => 'abc' })
    end

    it 'separates :query and :headers simultaneously, ignoring other keys' do
      opts = { query: { page: 1 }, headers: { 'X-Foo' => 'bar' }, extra: 'dropped' }
      query, headers = client.send(:parse_query_and_convenience_headers, opts)

      expect(query).to eq({ page: 1 })
      expect(headers).to eq({ 'X-Foo' => 'bar' })
    end
  end
end
