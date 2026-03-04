## [Unreleased]

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
