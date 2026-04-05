# frozen_string_literal: true

RSpec.describe TocDoc::Middleware::RateLimiter do
  let(:bucket) { instance_double(TocDoc::RateLimiter::TokenBucket) }
  let(:response) { Faraday::Response.new }
  let(:app) { proc { response } }

  subject(:middleware) { described_class.new(app, bucket: bucket) }

  describe '#call' do
    let(:env) { {} }

    before { allow(bucket).to receive(:acquire) }

    it 'acquires a token before forwarding the request' do
      middleware.call(env)
      expect(bucket).to have_received(:acquire)
    end

    it 'returns the response from the downstream app' do
      result = middleware.call(env)
      expect(result).to be(response)
    end
  end
end
