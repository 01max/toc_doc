## [Unreleased]

## [1.7.0] - 2026-04-04

### Added

- **`TocDoc::Middleware::Logging`** — new Faraday middleware that logs every outgoing request URL and the response status; plugged in automatically between the retry and raise-error layers; enabled via the new `logger` config key (accepts any Logger-compatible object; `nil` disables logging)
- **`logger` config key** — module-level and per-client option; also available as a `TocDoc::Default::LOGGER` constant (defaults to `nil`); each client instance carries its own logger, so multiple clients can log to different destinations simultaneously
- **`TocDoc::Resource#attribute_names`** — instance method returning the sorted list of attribute keys present on a resource instance
- **`TocDoc::Resource` singleton method definition on first access** — reader methods are now defined as true singleton methods on the instance the first time an attribute is accessed, eliminating repeated `respond_to?` / `method_missing` dispatch on subsequent calls

### Changed

- **`TocDoc::Resource#to_h`** — now performs a deep conversion: nested `Resource` objects and arrays of `Resource` objects are recursively converted; previously returned a shallow hash with raw attribute values
- **`TocDoc::Resource#to_json`** — delegates to the new deep `to_h`, so JSON output is fully recursive
- **`TocDoc::BookingInfo#to_h`** and **`#to_json`** — override `Resource`'s implementation to include all typed sub-objects (`profile`, `specialities`, `visit_motives`, `agendas`, `places`, `practitioners`) as deeply converted hashes
- **`TocDoc::BookingInfo#agendas`** — visit-motive resolution changed from O(n*m) nested iteration to O(n+m) hash lookup; no change to the public interface
- **`TocDoc::Availability::Collection#filtered_entries`** — result is now memoized; cache is invalidated automatically when `#merge_page!` appends a new page, preventing redundant filtering on repeated `#each` / `#to_a` calls
- **`#inspect`** for `TocDoc::Availability`, `TocDoc::Place`, `TocDoc::Speciality`, and `TocDoc::Profile::Organization`** — `main_attrs` declared on each class so inspect output stays concise; `TocDoc::Profile` and `TocDoc::Resource` inspect also improved

## [1.6.0] - 2026-03-30

### Added

- **Timeout configuration** — two new config keys: `connect_timeout` (TCP connect, default: `5`, env: `TOCDOC_CONNECT_TIMEOUT`) and `read_timeout` (response read, default: `10`, env: `TOCDOC_READ_TIMEOUT`); passed to Faraday as `open_timeout` and `timeout` respectively
- **`per_page` guard** — `TocDoc::Configurable` now emits a warning when `per_page` exceeds the maximum value the Doctolib API can handle
- **`TocDoc::Error` hierarchy** — structured error subclasses; `TocDoc::ResponseError` carries `status`, `body`, and `headers`; specific subclasses: `BadRequest` (400), `NotFound` (404), `UnprocessableEntity` (422), `TooManyRequests` (429), `ClientError` (other 4xx), `ServerError` (5xx); `TocDoc::ConnectionError` raised on network/transport failures
- **`TocDoc::Middleware::RaiseError`** — reworked to map HTTP error codes to structured `TocDoc::Error` subclasses; wraps Faraday transport errors (`TimeoutError`, `ConnectionFailed`, `SSLError`) into `TocDoc::ConnectionError`
- **`Default.reset!`** — class method to reset memoized middleware defaults, preventing middleware stack leak between configurations

### Changed

- **Max retry** — retry limit logic moved from `BaseMiddleware` into `TocDoc::Default`, eliminating the `BaseMiddleware` class; retry count now derived solely from `Default::MAX_RETRY`

## [1.5.0] - 2026-03-28

### Added

- **`TocDoc::BookingInfo`** — new envelope class for the slot-selection funnel info endpoint (`/online_booking/api/slot_selection_funnel/v1/info.json`); `BookingInfo.find(identifier)` fetches booking context by profile slug or numeric ID and returns a typed `BookingInfo` instance
- **`TocDoc::BookingInfo#profile`** — returns the typed profile (`Practitioner` or `Organization`) via `Profile.build`
- **`TocDoc::BookingInfo#specialities`** — returns an array of `TocDoc::Speciality` objects
- **`TocDoc::BookingInfo#visit_motives`** — returns an array of `TocDoc::VisitMotive` objects
- **`TocDoc::BookingInfo#agendas`** — returns an array of `TocDoc::Agenda` objects, each pre-resolved with its matching `VisitMotive` objects via `visit_motive_ids`
- **`TocDoc::BookingInfo#places`** — returns an array of `TocDoc::Place` objects
- **`TocDoc::BookingInfo#practitioners`** — returns an array of `TocDoc::Profile::Practitioner` objects (marked `partial: true`)
- **`TocDoc::BookingInfo#organization?`** — delegates to the inner profile
- **`TocDoc::VisitMotive`** — new `Resource`-based model representing a visit motive (reason for consultation); exposes `#id` and `#name` via dot-notation
- **`TocDoc::Agenda`** — new `Resource`-based model representing an agenda (calendar); exposes `#id` and `#practice_id` via dot-notation; supports pre-resolved `#visit_motives` when built through `BookingInfo`
- **`TocDoc.booking_info`** — top-level shortcut delegating to `TocDoc::BookingInfo.find`

## [1.4.0] - 2026-03-19

### Added

- **`TocDoc::Place`** — new `Resource`-based model representing a practice location inside a profile response; exposes address/geo fields (`#address`, `#zipcode`, `#city`, `#full_address`, `#landline_number`, `#latitude`, `#longitude`, `#elevator`, `#handicap`, `#formal_name`) via dot-notation and adds `#coordinates` returning `[latitude, longitude]`
- **`TocDoc::Profile.find`** — class method that fetches a full profile page by slug or numeric ID from `/profiles/:identifier.json`; returns a typed `Profile::Practitioner` or `Profile::Organization` with `partial: false`
- **`TocDoc::Profile#skills`** — returns all skills across every practice as an array of `TocDoc::Resource` objects
- **`TocDoc::Profile#skills_for(practice_id)`** — returns skills for a single practice
- **`TocDoc.profile`** — top-level shortcut delegating to `TocDoc::Profile.find`
- **`TocDoc::Resource.main_attrs`** — class macro declaring which attribute keys appear in `#inspect`; inheritable by subclasses
- **`TocDoc::Resource.normalize_attrs`** — extracted as a public class method (string-key normalisation)
- **`TocDoc::Resource#inspect`** — custom implementation using `main_attrs` when declared, falling back to all keys

### Changed

- **`TocDoc::Profile.build`** — updated to resolve full profile responses via boolean flags (`is_practitioner` / `organization`) in addition to the existing `owner_type` path used for search results; profiles built from search results are now tagged `partial: true`, full fetches `partial: false`; a `force_full_profile` flag on a search result transparently delegates to `Profile.find`
- **`TocDoc::Profile`** — `main_attrs :id, :partial` declared so inspect output stays concise

## [1.3.0] - 2026-03-15

### Added

- **`TocDoc::Speciality`** — new `Resource`-based model representing a speciality returned by the autocomplete endpoint; exposes `#value`, `#slug`, and `#name` via dot-notation
- **`TocDoc::Profile`** — new `Resource`-based model for search profile results; `Profile.build(attrs)` factory returns a `Profile::Practitioner` or `Profile::Organization` based on the `owner_type` field; provides `#practitioner?` and `#organization?` predicates
- **`TocDoc::Profile::Practitioner`** and **`TocDoc::Profile::Organization`** — typed profile subclasses
- **`TocDoc::Search`** — new service class for the autocomplete endpoint (`/api/searchbar/autocomplete.json`); `Search.where(query:, type: nil, **options)` fetches results and returns a `Search::Result`, or a filtered array when `type:` is one of `'profile'`, `'practitioner'`, `'organization'`, or `'speciality'`
- **`TocDoc::Search::Result`** — envelope returned by `Search.where`; exposes `#profiles` (typed via `Profile.build`) and `#specialities`; `#filter_by_type` narrows to a specific kind
- **`TocDoc.search`** — top-level shortcut delegating to `TocDoc::Search.where`

## [1.2.0] - 2026-03-08

### Added

- **`TocDoc::Availability::Collection`** — new `Enumerable` collection class returned by `TocDoc::Availability.where`; provides `#total`, `#next_slot`, `#each`, `#raw_availabilities`, `#to_h`, and `#merge_page!`
- **`TocDoc::Availability.where`** — class-level query method replacing `Client#availabilities`; automatically follows a `next_slot` response key with a second request before returning the collection
- **`TocDoc.availabilities`** — top-level shortcut delegating to `TocDoc::Availability.where`
- **Dependabot** — automated Bundler dependency updates via `.github/dependabot.yml`

### Changed

- **Connection** — `#get` and `#paginate` are now public on `TocDoc::Connection`, allowing model classes to call them directly via `TocDoc.client`
- **`TocDoc::UriUtils`** — updated module-level example to reflect actual usage (`TocDoc::Availability` with `extend`, not the removed `Client::Availabilities`)

### Removed

- **`TocDoc::Client::Availabilities`** — endpoint module removed; availability querying now lives in `TocDoc::Availability.where` and `TocDoc::Availability::Collection`
- **`TocDoc::Response::Availability`** — response wrapper model removed; replaced by `TocDoc::Availability::Collection`
- **`auto_paginate`** — configuration key, default, and all related logic removed from `TocDoc::Configurable` and `TocDoc::Default`

## [1.1.0] - 2026-03-06

### Changed

- **`TocDoc::Availability`** — `#date` now returns a parsed `Date` object instead of a raw string; `#slots` now returns an array of `DateTime` objects instead of strings
- **`TocDoc::Response::Availability#next_slot`** — falls back to inferring the next slot from the first available slot when the API response omits the `next_slot` key

### Removed

- **VCR** — removed VCR dependency from the test suite; HTTP interactions are now stubbed directly with WebMock

## [1.0.0] - 2026-03-04

### Added

- **Client** — `TocDoc::Client` with configurable options, method delegation from top-level `TocDoc` module, and block-based `TocDoc.setup`
- **Configuration** — 7 config keys (`api_endpoint`, `user_agent`, `middleware`, `connection_options`, `default_media_type`, `per_page`, `auto_paginate`) with environment variable overrides (`TOCDOC_API_ENDPOINT`, etc.)
- **Availabilities endpoint** — `Client#availabilities` supporting `visit_motive_ids`, `agenda_ids`, `start_date`, `limit`, and arbitrary extra query params
- **Pagination** — automatic multi-page fetching via `auto_paginate` option; merges results across pages using `next_slot`-based page advancement
- **Response models** — `TocDoc::Response::Availability` wrapping the API response with `#total`, `#next_slot`, `#availabilities` (filtered) and `#raw_availabilities` (unfiltered)
- **Resource base model** — `TocDoc::Resource` with dot-notation attribute access, bracket access, and Hash equality
- **Availability model** — `TocDoc::Availability` with `#date` and `#slots`
- **Error handling** — `TocDoc::Error` base class and `TocDoc::Middleware::RaiseError` Faraday middleware wrapping Faraday errors
- **Connection layer** — Faraday-based HTTP with `get`, `post`, `put`, `patch`, `delete`, `head` and a default middleware stack (retry, raise_error, JSON parsing)
- **Retry middleware** — automatic retries (up to 3, configurable via `TOCDOC_RETRY_MAX`) with exponential backoff on `429`, `5xx` errors
- **URI utilities** — `#dashed_ids` helper for Doctolib's dash-separated ID format
- **YARD documentation**

## [0.1.0] - 2026-02-27

- Initial build
