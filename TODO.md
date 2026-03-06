# PLAN

[POTENTIAL_ENDPOINTS][POTENTIAL_ENDPOINTS.md]

## 1.2

- [ ] Search (autocomplete)
  - [ ] search profile : https://www.doctolib.fr/api/searchbar/autocomplete.json?search=devun
  - [ ] search specialty : https://www.doctolib.fr/api/searchbar/autocomplete.json?search=dentiste

## 1.3

- [ ] Profile
  - slug : https://www.doctolib.fr/profiles/mathilde-devun-lesparre-medoc.json
  - id : https://www.doctolib.fr/profiles/926388.json

## 1.4

- [ ] Booking context
  - https://www.doctolib.fr/online_booking/api/slot_selection_funnel/v1/info.json?profile_slug=926388

## 1.5

### Better API usage
- [ ] Rate limiting
- [ ] Caching
- [ ] Logging

## 1.6

### Auth / User-based actions
- [ ] Research auth scheme
- [ ] Authentication module + headers
- [ ] Auth specs

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

## 1.1

### Parse raw API data
- [x] Parse date / datetime

[def]: PO