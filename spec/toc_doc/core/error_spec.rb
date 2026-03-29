# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TocDoc::Error do
  it 'is a StandardError' do
    expect(described_class.ancestors).to include(StandardError)
  end

  it 'is not a Faraday error (Faraday is hidden from consumers)' do
    expect(described_class.ancestors).not_to include(Faraday::Error)
  end
end

RSpec.describe TocDoc::ConnectionError do
  it 'is a TocDoc::Error' do
    expect(described_class.ancestors).to include(TocDoc::Error)
  end

  it 'is a StandardError' do
    expect(described_class.ancestors).to include(StandardError)
  end

  it 'can be raised with a plain message' do
    expect { raise described_class, 'timeout' }.to raise_error(TocDoc::ConnectionError, 'timeout')
  end
end

RSpec.describe TocDoc::ResponseError do
  subject(:error) { described_class.new(status: 500, body: 'oops', headers: { 'x-id' => '1' }) }

  it 'is a TocDoc::Error' do
    expect(described_class.ancestors).to include(TocDoc::Error)
  end

  it 'exposes status' do
    expect(error.status).to eq(500)
  end

  it 'exposes body' do
    expect(error.body).to eq('oops')
  end

  it 'exposes headers' do
    expect(error.headers).to eq({ 'x-id' => '1' })
  end

  it 'defaults message to "HTTP <status>"' do
    expect(error.message).to eq('HTTP 500')
  end

  it 'accepts a custom message' do
    err = described_class.new(status: 500, message: 'custom')
    expect(err.message).to eq('custom')
  end

  it 'allows nil body and headers' do
    err = described_class.new(status: 503)
    expect(err.body).to be_nil
    expect(err.headers).to be_nil
  end
end

RSpec.describe TocDoc::ClientError do
  it 'is a TocDoc::ResponseError' do
    expect(described_class.ancestors).to include(TocDoc::ResponseError)
  end

  it 'is a TocDoc::Error' do
    expect(described_class.ancestors).to include(TocDoc::Error)
  end
end

RSpec.describe TocDoc::BadRequest do
  it 'is a TocDoc::ClientError' do
    expect(described_class.ancestors).to include(TocDoc::ClientError)
  end

  it 'defaults message to "HTTP 400"' do
    expect(described_class.new(status: 400).message).to eq('HTTP 400')
  end
end

RSpec.describe TocDoc::NotFound do
  it 'is a TocDoc::ClientError' do
    expect(described_class.ancestors).to include(TocDoc::ClientError)
  end

  it 'defaults message to "HTTP 404"' do
    expect(described_class.new(status: 404).message).to eq('HTTP 404')
  end
end

RSpec.describe TocDoc::UnprocessableEntity do
  it 'is a TocDoc::ClientError' do
    expect(described_class.ancestors).to include(TocDoc::ClientError)
  end

  it 'defaults message to "HTTP 422"' do
    expect(described_class.new(status: 422).message).to eq('HTTP 422')
  end
end

RSpec.describe TocDoc::TooManyRequests do
  it 'is a TocDoc::ClientError' do
    expect(described_class.ancestors).to include(TocDoc::ClientError)
  end

  it 'defaults message to "HTTP 429"' do
    expect(described_class.new(status: 429).message).to eq('HTTP 429')
  end
end

RSpec.describe TocDoc::ServerError do
  it 'is a TocDoc::ResponseError' do
    expect(described_class.ancestors).to include(TocDoc::ResponseError)
  end

  it 'is a TocDoc::Error' do
    expect(described_class.ancestors).to include(TocDoc::Error)
  end

  it 'defaults message to "HTTP 500"' do
    expect(described_class.new(status: 500).message).to eq('HTTP 500')
  end
end

RSpec.describe TocDoc::Middleware::RaiseError do
  let(:stubs) { Faraday::Adapter::Test::Stubs.new }

  # No Faraday :raise_error — our middleware owns all error mapping.
  let(:conn) do
    Faraday.new do |builder|
      builder.use TocDoc::Middleware::RaiseError
      builder.adapter :test, stubs
    end
  end

  def stub_status(status, body: '', headers: {})
    stubs.get('/test') { [status, headers, body] }
    conn.get('/test')
  end

  # --- success ---

  it 'does not raise for 200' do
    expect { stub_status(200) }.not_to raise_error
  end

  it 'does not raise for 201' do
    expect { stub_status(201) }.not_to raise_error
  end

  # --- specific 4xx mappings ---

  it 'raises TocDoc::BadRequest for 400' do
    expect { stub_status(400) }.to raise_error(TocDoc::BadRequest)
  end

  it 'raises TocDoc::NotFound for 404' do
    expect { stub_status(404) }.to raise_error(TocDoc::NotFound)
  end

  it 'raises TocDoc::UnprocessableEntity for 422' do
    expect { stub_status(422) }.to raise_error(TocDoc::UnprocessableEntity)
  end

  it 'raises TocDoc::TooManyRequests for 429' do
    expect { stub_status(429) }.to raise_error(TocDoc::TooManyRequests)
  end

  # --- generic 4xx fallback ---

  it 'raises TocDoc::ClientError for unmapped 4xx (403)' do
    expect { stub_status(403) }.to raise_error(TocDoc::ClientError)
  end

  it 'raises TocDoc::ClientError for unmapped 4xx (409)' do
    expect { stub_status(409) }.to raise_error(TocDoc::ClientError)
  end

  # --- 5xx ---

  it 'raises TocDoc::ServerError for 500' do
    expect { stub_status(500) }.to raise_error(TocDoc::ServerError)
  end

  it 'raises TocDoc::ServerError for 503' do
    expect { stub_status(503) }.to raise_error(TocDoc::ServerError)
  end

  # --- HTTP context carried on the error ---

  it 'carries the HTTP status on the raised error' do
    stub_status(404)
  rescue TocDoc::ResponseError => e
    expect(e.status).to eq(404)
  end

  it 'carries the response body on the raised error' do
    stub_status(422, body: 'invalid')
  rescue TocDoc::ResponseError => e
    expect(e.body).to eq('invalid')
  end

  it 'carries response headers on the raised error' do
    stub_status(400, headers: { 'x-request-id' => 'abc' })
  rescue TocDoc::ResponseError => e
    expect(e.headers).to include('x-request-id' => 'abc')
  end

  # --- Faraday not exposed ---

  it 'does not expose Faraday in the raised error class' do
    stub_status(404)
  rescue StandardError => e
    expect(e).not_to be_a(Faraday::Error)
    expect(e).to be_a(TocDoc::Error)
  end

  # --- transport / connection errors ---

  it 'raises TocDoc::ConnectionError on Faraday::TimeoutError' do
    stubs.get('/test') { raise Faraday::TimeoutError, 'timed out' }
    expect { conn.get('/test') }.to raise_error(TocDoc::ConnectionError, 'timed out')
  end

  it 'raises TocDoc::ConnectionError on Faraday::ConnectionFailed' do
    stubs.get('/test') { raise Faraday::ConnectionFailed, 'refused' }
    expect { conn.get('/test') }.to raise_error(TocDoc::ConnectionError, 'refused')
  end

  it 'raises TocDoc::ConnectionError on Faraday::SSLError' do
    stubs.get('/test') { raise Faraday::SSLError, 'ssl failure' }
    expect { conn.get('/test') }.to raise_error(TocDoc::ConnectionError, 'ssl failure')
  end

  it 'does not expose Faraday in a ConnectionError' do
    stubs.get('/test') { raise Faraday::TimeoutError, 'timeout' }
    conn.get('/test')
  rescue StandardError => e
    expect(e).to be_a(TocDoc::ConnectionError)
    expect(e).not_to be_a(Faraday::Error)
  end
end
