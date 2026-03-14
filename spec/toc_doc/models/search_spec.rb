# frozen_string_literal: true

RSpec.describe TocDoc::Search do
  let(:base_url) { 'https://www.doctolib.fr/api/searchbar/autocomplete.json' }

  def stub_search(fixture_file, query: 'dentiste')
    stub_request(:get, base_url)
      .with(query: { search: query })
      .to_return(
        status: 200,
        body: fixture(fixture_file),
        headers: { 'Content-Type' => 'application/json' }
      )
  end

  describe '.where' do
    context 'with autocomplete-profile.json fixture (practitioner results)' do
      before { stub_search('autocomplete-profile.json') }

      it 'calls the correct endpoint' do
        TocDoc::Search.where(query: 'dentiste')
        expect(a_request(:get, base_url).with(query: { search: 'dentiste' })).to have_been_made.once
      end

      context 'without type:' do
        it 'returns a Search::Result' do
          expect(TocDoc::Search.where(query: 'dentiste')).to be_a(TocDoc::Search::Result)
        end
      end

      context "with type: 'profile'" do
        it 'returns an Array of Profile instances' do
          result = TocDoc::Search.where(query: 'dentiste', type: 'profile')
          expect(result).to be_an(Array)
          expect(result).to all(be_a(TocDoc::Profile))
        end
      end

      context "with type: 'practitioner'" do
        it 'returns only Profile::Practitioner instances' do
          result = TocDoc::Search.where(query: 'dentiste', type: 'practitioner')
          expect(result).to be_an(Array)
          expect(result).to all(be_a(TocDoc::Profile::Practitioner))
        end
      end

      context "with type: 'organization'" do
        it 'returns an empty array (fixture has no organizations)' do
          result = TocDoc::Search.where(query: 'dentiste', type: 'organization')
          expect(result).to eq([])
        end
      end

      context "with type: 'specialty'" do
        it 'returns an empty array (fixture has no specialities)' do
          result = TocDoc::Search.where(query: 'dentiste', type: 'specialty')
          expect(result).to eq([])
        end
      end

      context 'with an invalid type:' do
        it 'raises ArgumentError before making any HTTP request' do
          expect { TocDoc::Search.where(query: 'dentiste', type: 'bogus') }
            .to raise_error(ArgumentError, /bogus/)
          expect(a_request(:get, base_url)).not_to have_been_made
        end
      end
    end

    context 'with autocomplete-specialty.json fixture (organization + specialty results)' do
      before { stub_search('autocomplete-specialty.json') }

      it 'returns Profile::Organization instances for type: profile' do
        result = TocDoc::Search.where(query: 'dentiste', type: 'profile')
        expect(result).to all(be_a(TocDoc::Profile::Organization))
      end

      it 'returns Specialty instances for type: specialty' do
        result = TocDoc::Search.where(query: 'dentiste', type: 'specialty')
        expect(result).to be_an(Array)
        expect(result).not_to be_empty
        expect(result).to all(be_a(TocDoc::Specialty))
      end

      it 'populates both profiles and specialities in the full result' do
        result = TocDoc::Search.where(query: 'dentiste')
        expect(result.profiles).not_to be_empty
        expect(result.specialities).not_to be_empty
      end
    end
  end

  describe 'module-level delegation' do
    before do
      TocDoc.reset!
      stub_search('autocomplete-profile.json')
    end

    after { TocDoc.reset! }

    it 'TocDoc.search delegates to Search.where' do
      result = TocDoc.search(query: 'dentiste')
      expect(result).to be_a(TocDoc::Search::Result)
    end
  end
end
