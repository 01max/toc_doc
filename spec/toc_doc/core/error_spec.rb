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

  let(:conn) do
    Faraday.new do |builder|
      builder.use TocDoc::Middleware::RaiseError
      builder.response :raise_error
      builder.adapter :test, stubs
    end
  end

  def stub(status)
    stubs.get('/test') do
      [status, {}, '']
    end
    conn.get('/test')
  end

  it 'does not raise for 200' do
    expect { stub(200) }.not_to raise_error
  end

  [400, 404, 422, 429, 500, 503].each do |status|
    it "raises TocDoc::Error for #{status}" do
      expect { stub(status) }.to raise_error(TocDoc::Error)
    end
  end

  it 'does not expose Faraday in the raised class' do
    stub(404)
  rescue StandardError => e
    expect(e).not_to be_a(Faraday::Error)
    expect(e).to be_a(TocDoc::Error)
  end
end
