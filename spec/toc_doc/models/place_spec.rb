# frozen_string_literal: true

RSpec.describe TocDoc::Place do
  subject(:place) do
    described_class.new(
      'id' => 'practice-125055',
      'address' => '1 Rue Anonyme',
      'zipcode' => '33000',
      'city' => 'Bordeaux',
      'full_address' => '1 Rue Anonyme, 33000 Bordeaux',
      'landline_number' => '05 23 45 67 89',
      'latitude' => 44.8386722,
      'longitude' => -0.5780466,
      'elevator' => true,
      'handicap' => true,
      'formal_name' => 'Centre de santé - Anonyme',
      'opening_hours' => [
        { 'day' => 1, 'ranges' => [['08:00', '13:00'], ['14:00', '19:00']], 'enabled' => true }
      ],
      'stations' => [
        { 'transport_type' => 'tram', 'lines' => %w[A B], 'name' => 'Hôtel de Ville' }
      ]
    )
  end

  describe '#inspect' do
    it 'includes declared main_attrs' do
      expect(place.inspect).to include('@id=').and include('@city=').and include('@full_address=')
    end

    it 'excludes undeclared attrs' do
      expect(place.inspect).not_to include('@latitude=')
    end
  end

  it 'exposes id' do
    expect(place.id).to eq('practice-125055')
  end

  it 'exposes address' do
    expect(place.address).to eq('1 Rue Anonyme')
  end

  it 'exposes zipcode' do
    expect(place.zipcode).to eq('33000')
  end

  it 'exposes city' do
    expect(place.city).to eq('Bordeaux')
  end

  it 'exposes full_address' do
    expect(place.full_address).to eq('1 Rue Anonyme, 33000 Bordeaux')
  end

  it 'exposes landline_number' do
    expect(place.landline_number).to eq('05 23 45 67 89')
  end

  it 'exposes latitude' do
    expect(place.latitude).to eq(44.8386722)
  end

  it 'exposes longitude' do
    expect(place.longitude).to eq(-0.5780466)
  end

  it 'exposes elevator' do
    expect(place.elevator).to be true
  end

  it 'exposes handicap' do
    expect(place.handicap).to be true
  end

  it 'exposes formal_name' do
    expect(place.formal_name).to eq('Centre de santé - Anonyme')
  end

  it 'exposes opening_hours as a raw Array of Hashes' do
    expect(place.opening_hours).to be_an(Array)
    expect(place.opening_hours.first['day']).to eq(1)
    expect(place.opening_hours.first['ranges']).to eq([['08:00', '13:00'], ['14:00', '19:00']])
  end

  it 'exposes stations as a raw Array of Hashes' do
    expect(place.stations).to be_an(Array)
    expect(place.stations.first['transport_type']).to eq('tram')
    expect(place.stations.first['lines']).to eq(%w[A B])
  end

  it 'supports bracket access' do
    expect(place['city']).to eq('Bordeaux')
  end

  it 'round-trips to a plain Hash via #to_h' do
    expect(place.to_h).to include('city' => 'Bordeaux', 'zipcode' => '33000')
  end

  describe '#coordinates' do
    it 'returns [latitude, longitude]' do
      expect(place.coordinates).to eq([44.8386722, -0.5780466])
    end
  end
end
