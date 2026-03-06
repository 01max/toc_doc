## 1.1

### Parse raw API data
- [x] Parse date / datetime

# PLAN 1.2+

### Extra Endpoints
- [ ] Identify additional endpoints
- [ ] Prioritize implementation of resource modules for those endpoints

## 1.2

### Better API usage
- [ ] Rate limiting
- [ ] Caching
- [ ] Logging

## 1.4

### Auth / User-based actions
- [ ] Research auth scheme
- [ ] Authentication module + headers
- [ ] Auth specs

# Potential Endpoints

- Interesting JSONs [GET]
  - Practitioner ? 
    - https://www.doctolib.fr/pharmacie/paris/pharmacie-faidherbe.json
    - https://www.doctolib.fr/dentiste/bordeaux/mathilde-devun-lesparre-medoc.json
    - https://www.doctolib.fr/a/b/mathilde-devun-lesparre-medoc.json
    - https://www.doctolib.fr/profiles/mathilde-devun-lesparre-medoc.json
  - Rassemblement practiciens / Place Practitioners collection
    - https://www.doctolib.fr/profiles/pavillon-de-la-mutualite-bordeaux-rue-vital-carles.json
  - Places
    - https://www.doctolib.fr/patient_app/place_autocomplete.json?query=47300
- Interesting NON JSONs
  - City practitioners (❗️JSON-LD in a script tag of an HTML page - data-id="removable-json-ld")
    - https://www.doctolib.fr/dentiste/bordeaux/
    - https://www.doctolib.fr/medecin-generaliste/bordeaux/
    - https://www.doctolib.fr/medecin-generaliste/villeneuve-sur-lot
- Non-interesting 
  - Legal links
    - https://www.doctolib.fr/search/footer_legal_links.json
  - FAQ
    - https://www.doctolib.fr/search/footer_public_content.json?hub_search=false&display_faq=true&speciality_id=2&place_id=18733 
  - Social media links
    - https://www.doctolib.fr/search/footer_social_media_links.json
  - New Booking [POST]
    - online_booking/draft/new.json

# DONE & RELEASED

## 1.0

### 1 – Skeleton & Tooling
- [x] Scaffold gem & layout
- [x] Gem spec metadata & deps
- [x] Lib structure (default/config/client/etc.)
- [x] CI workflow (RSpec + RuboCop)
- [x] RSpec + WebMock + VCR setup

### 2 – Configuration
- [x] Default options & ENV fallbacks
- [x] Configurable module (keys, reset, options)
- [x] Top-level TocDoc wiring (client, setup, delegation)
- [x] Config specs (module + client)

### 3 – Connection & HTTP
- [x] Connection module (agent, request helpers)
- [x] ~Faraday middleware~
- [x] URL building helpers
- [x] Connection specs

### 4 – Error Handling
- [x] Error base class & factory
- [x] Error subclasses (4xx/5xx)
- [x] RaiseError middleware
- [x] Error mapping specs

### 5 – Client & Availabilities
- [x] Client includes config + connection
- [x] Availabilities endpoint module
- [x] TocDoc.availabilities delegation
- [x] Availabilities specs (stubs/VCR)

### 6 – Response Objects
- [x] Resource wrapper
- [x] Availability objects
- [x] Client mapping to response objects
- [x] Response specs

### 8 – Pagination
- [x] Analyze pagination model
- [x] Implement Connection#paginate
- [x] Pagination config & specs

### 9 – Docs & Release
- [x] README
- [x] YARD docs
- [x] CHANGELOG
- [x] FIX GH CI
- [x] Build & publish gem
  - [x] on rubygem
  - [x] release on GH
  - [x] gem.coop/@maxime
- [x] Add test coverage tool