# frozen_string_literal: true

RSpec.describe TocDoc::Cache::MemoryStore do
  subject(:store) { described_class.new(default_ttl: 60) }

  describe '#write and #read' do
    it 'returns the written value on read' do
      store.write('key', 'value')
      expect(store.read('key')).to eq('value')
    end

    it 'stores any object type' do
      store.write('hash', { 'a' => 1 })
      expect(store.read('hash')).to eq({ 'a' => 1 })
    end
  end

  describe '#read' do
    it 'returns nil for a missing key' do
      expect(store.read('nonexistent')).to be_nil
    end

    it 'returns nil for an expired entry' do
      store.write('expiring', 'data', expires_in: 0.01)
      sleep(0.05)
      expect(store.read('expiring')).to be_nil
    end

    it 'evicts the expired entry on read' do
      store.write('expiring', 'data', expires_in: 0.01)
      sleep(0.05)
      store.read('expiring')
      # A second read should also return nil (not crash)
      expect(store.read('expiring')).to be_nil
    end
  end

  describe '#delete' do
    it 'removes the entry' do
      store.write('key', 'value')
      store.delete('key')
      expect(store.read('key')).to be_nil
    end
  end

  describe '#clear' do
    it 'removes all entries' do
      store.write('a', 1)
      store.write('b', 2)
      store.clear
      expect(store.read('a')).to be_nil
      expect(store.read('b')).to be_nil
    end
  end

  describe 'thread safety' do
    it 'handles concurrent reads and writes without errors' do
      errors = []
      threads = Array.new(20) do |i|
        Thread.new do
          store.write("key_#{i}", i)
          store.read("key_#{i}")
        rescue StandardError => e
          errors << e
        end
      end
      threads.each(&:join)
      expect(errors).to be_empty
    end
  end
end
