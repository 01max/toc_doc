# frozen_string_literal: true

require 'toc_doc/models/booking_info'

RSpec.describe TocDoc::BookingInfo do
  let(:endpoint_url) { 'https://www.doctolib.fr/online_booking/api/slot_selection_funnel/v1/info.json' }

  def stub_booking_info(fixture_file, identifier:)
    stub_request(:get, endpoint_url)
      .with(query: { profile_slug: identifier.to_s })
      .to_return(
        status: 200,
        body: fixture(fixture_file),
        headers: { 'Content-Type' => 'application/json' }
      )
  end

  describe '.find' do
    context 'with practitioner fixture' do
      before { stub_booking_info('booking-info-practitioner.json', identifier: 'jane-doe-bordeaux') }

      subject(:info) { described_class.find('jane-doe-bordeaux') }

      it 'returns a BookingInfo' do
        expect(info).to be_a(described_class)
      end

      it 'exposes a Profile::Practitioner profile' do
        expect(info.profile).to be_a(TocDoc::Profile::Practitioner)
      end

      it 'exposes the correct profile name' do
        expect(info.profile.name_with_title).to eq('Dr Jane DOE')
      end
    end

    context 'with organization fixture' do
      before { stub_booking_info('booking-info-organization.json', identifier: 325_629) }

      subject(:info) { described_class.find(325_629) }

      it 'returns a BookingInfo' do
        expect(info).to be_a(described_class)
      end

      it 'exposes a Profile::Organization profile' do
        expect(info.profile).to be_a(TocDoc::Profile::Organization)
      end

      it 'exposes the correct profile name' do
        expect(info.profile.name_with_title).to eq('Cabinet dentaire Anonyme')
      end
    end

    context 'when identifier is nil' do
      it 'raises ArgumentError without making any HTTP request' do
        expect { described_class.find(nil) }.to raise_error(ArgumentError, /nil/)
        expect(a_request(:get, endpoint_url)).not_to have_been_made
      end
    end
  end

  context 'with practitioner fixture' do
    before { stub_booking_info('booking-info-practitioner.json', identifier: 'jane-doe-bordeaux') }

    subject(:info) { described_class.find('jane-doe-bordeaux') }

    describe '#specialities' do
      it 'returns an Array of Speciality' do
        expect(info.specialities).to all(be_a(TocDoc::Speciality))
      end

      it 'contains one speciality' do
        expect(info.specialities.length).to eq(1)
      end
    end

    describe '#visit_motives' do
      it 'returns an Array of VisitMotive' do
        expect(info.visit_motives).to all(be_a(TocDoc::VisitMotive))
      end

      it 'contains the correct names' do
        names = info.visit_motives.map(&:name)
        expect(names).to include('Première consultation dentaire', 'Blanchiment des dents')
      end
    end

    describe '#agendas' do
      it 'returns an Array of Agenda' do
        expect(info.agendas).to all(be_a(TocDoc::Agenda))
      end

      it 'contains the correct agenda ID' do
        expect(info.agendas.map(&:id)).to include(2_359_638)
      end
    end

    describe '#places' do
      it 'returns an Array of Place' do
        expect(info.places).to all(be_a(TocDoc::Place))
      end

      it 'exposes city and address' do
        place = info.places.first
        expect(place.city).to eq('Bordeaux')
        expect(place.address).to eq('1 Rue Anonyme')
      end
    end

    describe '#practitioners' do
      it 'returns an Array of Profile::Practitioner' do
        expect(info.practitioners).to all(be_a(TocDoc::Profile::Practitioner))
      end

      it 'contains one practitioner' do
        expect(info.practitioners.length).to eq(1)
      end

      it 'marks practitioners as partial' do
        expect(info.practitioners).to all(have_attributes(partial: true))
      end
    end

    describe '#organization?' do
      it 'returns false for a practitioner profile' do
        expect(info.organization?).to be false
      end
    end

    describe '#to_h' do
      it 'returns the raw data hash' do
        expect(info.to_h).to be_a(Hash)
        expect(info.to_h).to have_key('profile')
        expect(info.to_h).to have_key('visit_motives')
      end
    end
  end

  context 'with organization fixture' do
    before { stub_booking_info('booking-info-organization.json', identifier: 325_629) }

    subject(:info) { described_class.find(325_629) }

    describe '#practitioners' do
      it 'returns 7 Profile::Practitioner instances' do
        expect(info.practitioners.length).to eq(7)
        expect(info.practitioners).to all(be_a(TocDoc::Profile::Practitioner))
      end
    end

    describe '#organization?' do
      it 'returns true for an organization profile' do
        expect(info.organization?).to be true
      end
    end
  end
end
