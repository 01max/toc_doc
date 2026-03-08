## [Unreleased]

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
