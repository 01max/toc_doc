# frozen_string_literal: true

RSpec.describe TocDoc::RateLimiter::TokenBucket do
  describe '.new' do
    context 'when rate is below minimum' do
      it 'clamps to 1 and emits a warning' do
        expect { described_class.new(rate: 0.5) }
          .to output(/rate_limit.*clamped to 1/).to_stderr
        bucket = described_class.new(rate: 0)
        expect(bucket.instance_variable_get(:@rate)).to eq(1.0)
      end
    end

    context 'when rate is exactly 1' do
      it 'does not emit a warning' do
        expect { described_class.new(rate: 1) }.not_to output.to_stderr
      end
    end
  end

  describe '#acquire' do
    context 'when tokens are available' do
      it 'returns immediately without sleeping' do
        bucket = described_class.new(rate: 10, interval: 1.0)
        start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        bucket.acquire
        elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start
        expect(elapsed).to be < 0.1
      end
    end

    context 'burst capacity' do
      it 'allows up to rate tokens without sleeping' do
        rate = 5
        bucket = described_class.new(rate: rate, interval: 1.0)
        start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        rate.times { bucket.acquire }
        elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start
        expect(elapsed).to be < 0.5
      end
    end

    context 'thread safety' do
      it 'allows concurrent calls without raising errors' do
        bucket = described_class.new(rate: 20, interval: 1.0)
        errors = []
        threads = Array.new(10) do
          Thread.new do
            2.times { bucket.acquire }
          rescue StandardError => e
            errors << e
          end
        end
        threads.each(&:join)
        expect(errors).to be_empty
      end
    end
  end
end
