# frozen_string_literal: true

require 'toc_doc/models/agenda'

RSpec.describe TocDoc::Agenda do
  subject(:agenda) do
    described_class.new(
      'id' => 42,
      'practice_id' => 'practice-125055',
      'visit_motive_ids' => [1, 2],
      'visit_motive_ids_by_practice_id' => { 'practice-125055' => [1, 2] }
    )
  end

  it 'exposes id' do
    expect(agenda.id).to eq(42)
  end

  it 'exposes practice_id' do
    expect(agenda.practice_id).to eq('practice-125055')
  end

  it 'exposes visit_motive_ids via dot-notation' do
    expect(agenda.visit_motive_ids).to eq([1, 2])
  end

  it 'exposes visit_motive_ids_by_practice_id via dot-notation' do
    expect(agenda.visit_motive_ids_by_practice_id).to eq('practice-125055' => [1, 2])
  end

  it 'supports bracket access' do
    expect(agenda['practice_id']).to eq('practice-125055')
  end

  it 'round-trips to a plain Hash via #to_h' do
    expect(agenda.to_h).to include('id' => 42, 'practice_id' => 'practice-125055')
  end

  it 'includes id and practice_id in #inspect' do
    expect(agenda.inspect).to include('@id=42', '@practice_id="practice-125055"')
  end
end
