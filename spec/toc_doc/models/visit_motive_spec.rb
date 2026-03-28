# frozen_string_literal: true

require 'toc_doc/models/visit_motive'

RSpec.describe TocDoc::VisitMotive do
  subject(:motive) do
    described_class.new(
      'id' => 1,
      'name' => 'Consultation',
      'restrictions' => [{ 'practice_id' => 'practice-125055', 'agenda_ids' => [42] }]
    )
  end

  it 'exposes id' do
    expect(motive.id).to eq(1)
  end

  it 'exposes name' do
    expect(motive.name).to eq('Consultation')
  end

  it 'exposes restrictions via dot-notation' do
    expect(motive.restrictions).to be_an(Array)
    expect(motive.restrictions.first['practice_id']).to eq('practice-125055')
  end

  it 'supports bracket access' do
    expect(motive['name']).to eq('Consultation')
  end

  it 'round-trips to a plain Hash via #to_h' do
    expect(motive.to_h).to include('id' => 1, 'name' => 'Consultation')
  end

  it 'includes id and name in #inspect' do
    expect(motive.inspect).to include('@id=1', '@name="Consultation"')
  end
end
