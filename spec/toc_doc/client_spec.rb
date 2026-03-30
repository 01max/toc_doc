# frozen_string_literal: true

RSpec.describe TocDoc::Client do
  it 'starts with default options' do
    client = described_class.new
    expect(client.api_endpoint).to eq(TocDoc::Default.api_endpoint)
    expect(client.per_page).to eq(TocDoc::Default.per_page)
  end

  it 'applies per-instance options over defaults' do
    client = described_class.new(api_endpoint: 'https://client.example', per_page: 10)

    expect(client.api_endpoint).to eq('https://client.example')
    expect(client.per_page).to eq(10)
  end

  it 'caps per_page at MAX_PER_PAGE and warns' do
    client = nil
    expect { client = described_class.new(per_page: 99) }
      .to output(/\[TocDoc\] per_page 99 exceeds MAX_PER_PAGE/).to_stderr
    expect(client.per_page).to eq(TocDoc::Default::MAX_PER_PAGE)
  end
end
