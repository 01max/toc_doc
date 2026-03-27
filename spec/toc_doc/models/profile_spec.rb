# frozen_string_literal: true

RSpec.describe TocDoc::Profile do
  let(:base_url) { 'https://www.doctolib.fr/profiles/jane-doe-bordeaux.json' }
  let(:numeric_url) { 'https://www.doctolib.fr/profiles/1542899.json' }

  def stub_profile(url = base_url)
    stub_request(:get, url)
      .to_return(
        status: 200,
        body: fixture('profile.json'),
        headers: { 'Content-Type' => 'application/json' }
      )
  end

  describe '.build' do
    context "when owner_type is 'Account'" do
      subject(:profile) { described_class.build('owner_type' => 'Account', 'name' => 'Dr Smith') }

      it 'returns a Profile::Practitioner' do
        expect(profile).to be_a(TocDoc::Profile::Practitioner)
      end
    end

    context "when owner_type is 'Organization'" do
      subject(:profile) { described_class.build('owner_type' => 'Organization', 'name' => 'Clinique du Parc') }

      it 'returns a Profile::Organization' do
        expect(profile).to be_a(TocDoc::Profile::Organization)
      end
    end

    context 'when owner_type is anything else' do
      it 'raises ArgumentError' do
        expect { described_class.build('owner_type' => 'Unknown') }.to raise_error(ArgumentError)
      end
    end

    context 'when attrs are empty' do
      it 'raises ArgumentError' do
        expect { described_class.build }.to raise_error(ArgumentError)
      end
    end

    context 'when is_practitioner is true (profile-page flag)' do
      it 'returns a Profile::Practitioner' do
        expect(described_class.build('is_practitioner' => true)).to be_a(TocDoc::Profile::Practitioner)
      end
    end

    context 'when organization is true (profile-page flag)' do
      it 'returns a Profile::Organization' do
        expect(described_class.build('organization' => true)).to be_a(TocDoc::Profile::Organization)
      end
    end

    context 'when organization is true and is_practitioner is absent (booking-info shape)' do
      subject(:profile) { described_class.build('organization' => true, 'name_with_title' => 'Cabinet Anonyme') }

      it 'returns a Profile::Organization' do
        expect(profile).to be_a(TocDoc::Profile::Organization)
      end

      it 'marks it as partial' do
        expect(profile.partial).to be true
      end
    end

    context 'when organization is false and is_practitioner is absent (booking-info shape)' do
      subject(:profile) { described_class.build('organization' => false, 'name_with_title' => 'Dr Jane DOE') }

      it 'returns a Profile::Practitioner' do
        expect(profile).to be_a(TocDoc::Profile::Practitioner)
      end

      it 'marks it as partial' do
        expect(profile.partial).to be true
      end
    end

    context 'when is_practitioner is true (full profile)' do
      subject(:profile) { described_class.build('is_practitioner' => true) }

      it 'marks it as not partial' do
        expect(profile.partial).to be false
      end
    end
  end

  describe '.find' do
    context 'with a slug identifier' do
      before { stub_profile }

      subject(:profile) { described_class.find('jane-doe-bordeaux') }

      it 'returns a Profile::Practitioner' do
        expect(profile).to be_a(TocDoc::Profile::Practitioner)
      end

      it 'exposes name' do
        expect(profile.name).to eq('DOE')
      end

      it 'exposes name_with_title' do
        expect(profile.name_with_title).to eq('Dr Jane DOE')
      end

      it 'exposes speciality as a TocDoc::Speciality' do
        expect(profile.speciality).to be_a(TocDoc::Speciality)
        expect(profile.speciality.name).to eq('Chirurgien-dentiste')
      end

      it 'exposes places as an array of TocDoc::Place' do
        expect(profile.places).to all(be_a(TocDoc::Place))
        expect(profile.places.length).to eq(1)
      end

      it 'exposes place city, address and full_address' do
        place = profile.places.first
        expect(place.city).to eq('Bordeaux')
        expect(place.address).to eq('1 Rue Anonyme')
        expect(place.full_address).to eq('1 Rue Anonyme, 33000 Bordeaux')
      end

      it 'exposes opening_hours as a raw Array of Hashes' do
        expect(profile.places.first.opening_hours).to be_an(Array)
        expect(profile.places.first.opening_hours.first['day']).to eq(1)
      end

      it 'exposes stations as a raw Array of Hashes' do
        expect(profile.places.first.stations).to be_an(Array)
        expect(profile.places.first.stations.first['transport_type']).to eq('tram')
      end

      it 'exposes legals as a raw Hash' do
        expect(profile.legals).to be_a(Hash)
        expect(profile.legals['rpps']).to eq('00000000000')
      end

      it 'exposes details as a raw Array of Hashes' do
        expect(profile.details).to be_an(Array)
        expect(profile.details.first['practice_id']).to eq(125_055)
      end

      it 'exposes bookable' do
        expect(profile.bookable).to be true
      end

      it '#skills returns a flat Array of 6 Resource items' do
        expect(profile.skills).to all(be_a(TocDoc::Resource))
        expect(profile.skills.length).to eq(6)
      end

      it '#skills_for returns the skills for a given practice_id' do
        expect(profile.skills_for(125_055).length).to eq(6)
      end
    end

    context 'with a numeric identifier' do
      before { stub_profile(numeric_url) }

      it 'returns a Profile::Practitioner' do
        expect(described_class.find(1_542_899)).to be_a(TocDoc::Profile::Practitioner)
      end
    end

    context 'when identifier is nil' do
      it 'raises ArgumentError without making any HTTP request' do
        expect { described_class.find(nil) }.to raise_error(ArgumentError, /nil/)
        expect(a_request(:get, /profiles/)).not_to have_been_made
      end
    end
  end

  describe '#practitioner?' do
    it 'returns true for a Practitioner' do
      expect(TocDoc::Profile::Practitioner.new).to be_practitioner
    end

    it 'returns false for an Organization' do
      expect(TocDoc::Profile::Organization.new).not_to be_practitioner
    end
  end

  describe '#organization?' do
    it 'returns true for an Organization' do
      expect(TocDoc::Profile::Organization.new).to be_organization
    end

    it 'returns false for a Practitioner' do
      expect(TocDoc::Profile::Practitioner.new).not_to be_organization
    end
  end

  describe 'dot-notation attribute access (inherited from Resource)' do
    subject(:profile) do
      described_class.build(
        'owner_type' => 'Account',
        'name' => 'Dr Alice Dupont',
        'city' => 'Lyon',
        'kind' => 'Dermatologue et vénérologue',
        'link' => '/dermatologue/lyon/alice-dupont',
        'value' => 1001
      )
    end

    it 'exposes name' do
      expect(profile.name).to eq('Dr Alice Dupont')
    end

    it 'exposes city' do
      expect(profile.city).to eq('Lyon')
    end

    it 'exposes kind' do
      expect(profile.kind).to eq('Dermatologue et vénérologue')
    end

    it 'exposes link' do
      expect(profile.link).to eq('/dermatologue/lyon/alice-dupont')
    end

    it 'exposes value' do
      expect(profile.value).to eq(1001)
    end

    it 'supports bracket access' do
      expect(profile['name']).to eq('Dr Alice Dupont')
    end

    it 'round-trips to a plain Hash via #to_h' do
      expect(profile.to_h).to include('name' => 'Dr Alice Dupont', 'city' => 'Lyon')
    end
  end

  describe 'TocDoc.profile module-level delegation' do
    before { stub_profile }

    it 'delegates to Profile.find and returns a Profile::Practitioner' do
      expect(TocDoc.profile('jane-doe-bordeaux')).to be_a(TocDoc::Profile::Practitioner)
    end
  end
end
