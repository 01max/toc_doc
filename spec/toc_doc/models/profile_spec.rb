# frozen_string_literal: true

RSpec.describe TocDoc::Profile do
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
      it 'defaults to Profile::Organization' do
        expect(described_class.build('owner_type' => 'Unknown')).to be_a(TocDoc::Profile::Organization)
      end
    end

    context 'when attrs are empty' do
      it 'defaults to Profile::Organization' do
        expect(described_class.build).to be_a(TocDoc::Profile::Organization)
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
        'kind' => 'Médecin généraliste',
        'link' => '/medecin-generaliste/lyon/alice-dupont',
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
      expect(profile.kind).to eq('Médecin généraliste')
    end

    it 'exposes link' do
      expect(profile.link).to eq('/medecin-generaliste/lyon/alice-dupont')
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
end
