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
