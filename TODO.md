# PLAN

[POTENTIAL_ENDPOINTS][POTENTIAL_ENDPOINTS.md]


## 1.8 — HTTP Layer Robustness

- [ ] Configurable availability pagination depth + `Collection#more?` / `#fetch_next_page`
- [ ] Client-side rate limiter (token-bucket middleware)
- [ ] Optional response caching (memory or ActiveSupport-compatible store)

## 1.9 — Service Layer rework

- [ ] `TocDoc::Services::Availabilities` — extract from `Availability.where`
- [ ] `TocDoc::Services::Profiles` — extract from `Profile.find`
- [ ] `TocDoc::Services::Search` — extract from `Search.where`
- [ ] `TocDoc::Services::BookingInfos` — extract from `BookingInfo.find`
- [ ] Update top-level shortcuts to delegate to services
- [ ] Deprecation on old model-level finders

## 2.0 — Breaking Changes

- [ ] Remove deprecated model-level finders
- [ ] `Place#coordinates` as `Data.define(:latitude, :longitude)`
- [ ] Integration smoke test suite (gated by ENV, weekly CI cron)
- [ ] Remove unused HTTP verbs from `Connection` (if auth doesn't ship)

# ???

- [ ] Figure what is `organization_statuses` in the autocomplete endpoint and what to do with it.
- [ ] Authentication module
- [ ] Place autocomplete endpoint ? (`/patient_app/place_autocomplete.json`)

# DONE & RELEASED

## 1.7

- [x] Logging middleware (`:logger` config key)
- [x] Resource: `define_singleton_method` on first access + `#attribute_names`
- [x] Deep `to_h` and `to_json` on `Resource` and `BookingInfo`
- [x] `Collection#filtered_entries` memoization
- [x] `BookingInfo#agendas` O(n*m) → hash lookup
- [x] Improve `#inspect` for `Availability`, `Place`, `Speciality`, `Profile::Organization`

## 1.6

### Default connection timeouts
- [x] Add `CONNECT_TIMEOUT` and `READ_TIMEOUT` constants to `Default`
- [x] Add config keys and ENV overrides (`TOCDOC_CONNECT_TIMEOUT`, `TOCDOC_READ_TIMEOUT`)
- [x] Wire into `Connection#faraday_options`

### Error hierarchy with HTTP context
- [x] Build error subclass tree (`ConnectionError`, `ResponseError`, `ClientError`, `NotFound`, `TooManyRequests`, `ServerError`)
- [x] Rewrite `RaiseError` middleware (`on_complete` pattern, status → subclass mapping)
- [x] Remove `Faraday::Response::RaiseError` from middleware stack

### Fixes
- [x] Fix middleware memoization leak (`Default.reset!`)
- [x] Warn on silent `per_page` clamping
- [x] Remove dead code (`base_middleware.rb`, `retry_options_fallback` duplication)

## 1.5

- [x] Booking context
  - practitioner : https://www.doctolib.fr/online_booking/api/slot_selection_funnel/v1/info.json?profile_slug=926388
  - organization : https://www.doctolib.fr/online_booking/api/slot_selection_funnel/v1/info.json?profile_slug=325629

## 1.4

- [x] Profile
  - from slug : https://www.doctolib.fr/profiles/jane-doe-bordeaux.json
  - from id : https://www.doctolib.fr/profiles/926388.json

## 1.3

- [x] Search (autocomplete)
  - [x] search profile : https://www.doctolib.fr/api/searchbar/autocomplete.json?search=devun
  - [x] search specialty : https://www.doctolib.fr/api/searchbar/autocomplete.json?search=dentiste

## 1.2

- [x] Rework Availability's client, model and collection architecture.

## 1.1

### Parse raw API data
- [x] Parse date / datetime

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
