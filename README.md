# TocDoc

A Ruby gem for interacting with the (unofficial) Doctolib API. A thin, Faraday-based client with configurable defaults, model-driven resource querying, and a clean error hierarchy.

[![Gem Version](https://badge.fury.io/rb/toc_doc.svg)](https://badge.fury.io/rb/toc_doc)
[![CI](https://github.com/01max/toc_doc/actions/workflows/main.yml/badge.svg)](https://github.com/01max/toc_doc/actions)
[![Coverage Status](https://coveralls.io/repos/github/01max/toc_doc/badge.svg?branch=main)](https://coveralls.io/github/01max/toc_doc?branch=main)
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![YARD Docs](https://img.shields.io/badge/docs-YARD-blue.svg)](https://rubydoc.info/gems/toc_doc)

> **Heads-up:** Doctolib™ does not publish a public API. This gem reverse-engineers
> the endpoints used by the Doctolib™ website. Behaviour may change at any time
> without notice. This project is for entertainment purposes only.
> Doctolib is a trademark of Doctolib. This project is not affiliated with,
> endorsed by, or sponsored by Doctolib.

---

## Contents

1. [Installation](#installation)
2. [Quick start](#quick-start)
3. [Configuration](#configuration)
   - [Module-level](#module-level-configuration)
   - [Per-client](#per-client-configuration)
   - [All options](#all-configuration-options)
   - [ENV variables](#environment-variable-overrides)
4. [Endpoints](#endpoints)
   - [Availabilities](#availabilities)
   - [Search](#search)
   - [Profile](#profile)
   - [BookingInfo](#bookinginfo)
5. [Response objects](#response-objects)
6. [Pagination](#pagination)
7. [Error handling](#error-handling)
8. [Development](#development)
   - [Generating documentation](#generating-documentation)
9. [Contributing](#contributing)
10. [Code of Conduct](#code-of-conduct)
11. [License](#license)

---

## Installation

Add the gem to your `Gemfile`:

```ruby
gem 'toc_doc'
```

then run:

```bash
bundle install
```

or install it directly:

```bash
gem install toc_doc
```

---

## Quick start

```ruby
require 'toc_doc'

collection = TocDoc::Availability.where(
  visit_motive_ids: 7_767_829,
  agenda_ids:       1_101_600,
  practice_ids:     377_272,
  telehealth:       false
)

collection.total      # => 5
collection.next_slot  # => "2026-02-28T10:00:00.000+01:00"

collection.each do |avail|
  puts "#{avail.date}: #{avail.slots.map { |s| s.strftime('%H:%M') }.join(', ')}"
end
```

---

## Configuration

### Module-level configuration

Set options once at startup and every subsequent call will share them:

```ruby
TocDoc.configure do |config|
  config.api_endpoint = 'https://www.doctolib.de'   # target country
  config.per_page     = 10
end

TocDoc::Availability.where(visit_motive_ids: 123, agenda_ids: 456)
```

Calling `TocDoc.reset!` restores all options to their defaults.  
Use `TocDoc.options` to inspect the current configuration hash.

### Per-client configuration

Instantiate independent clients with different options and query via `TocDoc::Availability.where`:

```ruby
# Germany
TocDoc.configure { |c| c.api_endpoint = 'https://www.doctolib.de'; c.per_page = 3 }
TocDoc::Availability.where(visit_motive_ids: 123, agenda_ids: 456)

# Reset and switch to Italy
TocDoc.reset!
TocDoc.configure { |c| c.api_endpoint = 'https://www.doctolib.it' }
TocDoc::Availability.where(visit_motive_ids: 789, agenda_ids: 101)
```

Alternatively, use `TocDoc::Client` directly for lower-level access ().

```ruby
client = TocDoc::Client.new(api_endpoint: 'https://www.doctolib.de', per_page: 5)
client.get('/availabilities.json', query: { visit_motive_ids: '123', agenda_ids: '456', start_date: Date.today.to_s, limit: 5 })
```

### All configuration options

| Option | Default | Description |
|---|---|---|
| `api_endpoint` | `https://www.doctolib.fr` | Base URL. Change to `.de` / `.it` for other countries. |
| `user_agent` | `TocDoc Ruby Gem 1.5.0` | `User-Agent` header sent with every request. |
| `default_media_type` | `application/json` | `Accept` and `Content-Type` headers. |
| `per_page` | `15` | Default number of availability dates per request (capped at `15`). |
| `middleware` | Retry + RaiseError + JSON + adapter | Full Faraday middleware stack. Override to customise completely. |
| `connection_options` | `{}` | Options passed directly to `Faraday.new`. |

### Environment variable overrides

All primary options can be set via environment variables before the gem is loaded:

| Variable | Option |
|---|---|
| `TOCDOC_API_ENDPOINT` | `api_endpoint` |
| `TOCDOC_USER_AGENT` | `user_agent` |
| `TOCDOC_MEDIA_TYPE` | `default_media_type` |
| `TOCDOC_PER_PAGE` | `per_page` |
| `TOCDOC_RETRY_MAX` | Maximum Faraday retry attempts (default `3`) |

---

## Endpoints

### Availabilities

Retrieve open appointment slots for a given visit motive and agenda.

```ruby
TocDoc::Availability.where(
  visit_motive_ids: visit_motive_id,   # Integer, String, or Array
  agenda_ids:       agenda_id,         # Integer, String, or Array
  start_date:       Date.today,        # Date or String (default: today)
  limit:            5,                 # override per_page for this call
  # any extra keyword args are forwarded verbatim as query params:
  practice_ids:     377_272,
  telehealth:       false
)
```

`TocDoc.availabilities(...)` is a module-level shortcut with the same signature.

**Multiple IDs** are accepted as arrays; the gem serialises them with the
dash-separated format Doctolib expects:

```ruby
TocDoc::Availability.where(
  visit_motive_ids: [7_767_829, 7_767_830],
  agenda_ids:       [1_101_600, 1_101_601]
)
# → GET /availabilities.json?visit_motive_ids=7767829-7767830&agenda_ids=1101600-1101601&…
```

**Return value:** a `TocDoc::Availability::Collection` (see [Response objects](#response-objects)).

### Search

Query the Doctolib autocomplete endpoint to look up practitioners, organizations, and specialities.

```ruby
result = TocDoc::Search.where(query: 'dentiste')
result.profiles      # => [#<TocDoc::Profile::Practitioner ...>, ...]
result.specialities  # => [#<TocDoc::Speciality ...>, ...]
```

Pass `type:` to receive a filtered array directly:

```ruby
# Only specialities
TocDoc::Search.where(query: 'cardio', type: 'speciality')
# => [#<TocDoc::Speciality name="Cardiologue">, ...]

# Only practitioners
TocDoc::Search.where(query: 'dupont', type: 'practitioner')
# => [#<TocDoc::Profile::Practitioner ...>, ...]
```

Valid `type:` values: `'profile'` (all profiles), `'practitioner'`, `'organization'`, `'speciality'`.

`TocDoc.search(...)` is a module-level shortcut with the same signature.

**Return value:** a `TocDoc::Search::Result` when `type:` is omitted, or a filtered `Array` otherwise (see [Response objects](#response-objects)).

### Profile

Fetch a full practitioner or organization profile page by slug or numeric ID.

```ruby
# by slug
profile = TocDoc::Profile.find('jane-doe-bordeaux')

# by numeric ID
profile = TocDoc::Profile.find(1_542_899)

# module-level shortcut
profile = TocDoc.profile('jane-doe-bordeaux')
```

`Profile.find` returns a typed `TocDoc::Profile::Practitioner` or `TocDoc::Profile::Organization` instance with `partial: false` (i.e. full profile data).

```ruby
profile.name            # => "Dr. Jane Doe"
profile.partial         # => false
profile.practitioner?   # => true

profile.skills          # => [#<TocDoc::Resource ...>, ...]
profile.skills_for(377_272)  # => skills for a specific practice

profile.places.first.city              # => "Bordeaux"
profile.places.first.coordinates       # => [44.8386722, -0.5780466]
```

**Return value:** a `TocDoc::Profile::Practitioner` or `TocDoc::Profile::Organization` (see [Response objects](#response-objects)).

### BookingInfo

Fetch the slot-selection funnel context for a practitioner or organization by slug or numeric ID.

```ruby
# by slug
info = TocDoc::BookingInfo.find('jane-doe-bordeaux')

# by numeric ID
info = TocDoc::BookingInfo.find(1_542_899)

# module-level shortcut
info = TocDoc.booking_info('jane-doe-bordeaux')
```

`BookingInfo.find` hits `/online_booking/api/slot_selection_funnel/v1/info.json` and returns a `TocDoc::BookingInfo` instance containing the full booking context needed to drive the appointment-booking funnel.

```ruby
info.profile        # => #<TocDoc::Profile::Practitioner ...>
info.specialities   # => [#<TocDoc::Speciality ...>, ...]
info.visit_motives  # => [#<TocDoc::VisitMotive id=..., name="...">, ...]
info.agendas        # => [#<TocDoc::Agenda id=..., practice_id=...>, ...]
info.places         # => [#<TocDoc::Place ...>, ...]
info.practitioners  # => [#<TocDoc::Profile::Practitioner partial=true>, ...]
info.organization?  # => false
```

**Return value:** a `TocDoc::BookingInfo` (see [Response objects](#response-objects)).

---

## Response objects

All API responses are wrapped in lightweight Ruby objects that provide
dot-notation access and a `#to_h` round-trip helper.

### `TocDoc::Availability::Collection`

Returned by `TocDoc::Availability.where`; also accessible via the `TocDoc.availabilities` module-level shortcut.
Implements `Enumerable`, yielding `TocDoc::Availability` instances that have at least one slot.

| Method | Type | Description |
|---|---|---|
| `#total` | `Integer` | Total number of available slots across all dates. |
| `#next_slot` | `String \| nil` | ISO 8601 datetime of the nearest available slot. `nil` when none remain. |
| `#each` | — | Yields each `TocDoc::Availability` that has at least one slot (excludes empty-slot dates). |
| `#raw_availabilities` | `Array<TocDoc::Availability>` | All date entries, including those with no slots. |
| `#to_h` | `Hash` | Plain-hash representation (only dates with slots in the `availabilities` key). |

### `TocDoc::Availability`

Represents a single availability date entry. Each element yielded by the collection.

| Method | Type | Description |
|---|---|---|
| `#date` | `Date` | Parsed date object. |
| `#slots` | `Array<DateTime>` | Parsed datetime objects for each bookable slot on that date. |
| `#to_h` | `Hash` | Plain-hash representation. |

**Example:**

```ruby
collection = TocDoc::Availability.where(visit_motive_ids: 123, agenda_ids: 456)

collection.total      # => 5
collection.next_slot  # => "2026-02-28T10:00:00.000+01:00"

collection.first.date   # => #<Date: 2026-02-28>
collection.first.slots  # => [#<DateTime: 2026-02-28T10:00:00+01:00>, ...]

collection.to_h
# => {
#      "total"          => 5,
#      "next_slot"      => "2026-02-28T10:00:00.000+01:00",
#      "availabilities" => [{ "date" => "2026-02-28", "slots" => [...] }, ...]
#    }
```

### `TocDoc::Search::Result`

Returned by `TocDoc::Search.where` when `type:` is omitted.

| Method | Type | Description |
|---|---|---|
| `#profiles` | `Array<TocDoc::Profile::Practitioner, TocDoc::Profile::Organization>` | All profile results, typed via `Profile.build`. |
| `#specialities` | `Array<TocDoc::Speciality>` | All speciality results. |
| `#filter_by_type(type)` | `Array` | Narrows results to `'profile'`, `'practitioner'`, `'organization'`, or `'speciality'`. |

### `TocDoc::Profile`

Represents a practitioner or organization profile. Can be a lightweight search result (`partial: true`) or a full profile page (`partial: false`).

| Method | Type | Description |
|---|---|---|
| `Profile.find(identifier)` | `Profile::Practitioner \| Profile::Organization` | Fetches a full profile by slug or numeric ID. Returns `partial: false`. |
| `Profile.build(attrs)` | `Profile::Practitioner \| Profile::Organization` | Factory used internally by `Search::Result`; resolves type from `owner_type` or boolean flags. Returns `partial: true` for search results. |
| `#id` | `String \| Integer` | Profile identifier. |
| `#partial` | `Boolean` | `true` when built from a search result, `false` when fetched via `Profile.find`. |
| `#practitioner?` | `Boolean` | `true` when this is a `Profile::Practitioner`. |
| `#organization?` | `Boolean` | `true` when this is a `Profile::Organization`. |
| `#places` | `Array<TocDoc::Place>` | Practice locations (available on full profiles). |
| `#skills` | `Array<TocDoc::Resource>` | All skills across every practice (available on full profiles). |
| `#skills_for(practice_id)` | `Array<TocDoc::Resource>` | Skills for a single practice by its ID. |

`TocDoc::Profile::Practitioner` and `TocDoc::Profile::Organization` are typed subclasses that inherit dot-notation attribute access from `TocDoc::Resource`.

### `TocDoc::Place`

Represents a practice location returned inside a full profile response. Inherits dot-notation attribute access from `TocDoc::Resource`.

| Method | Type | Description |
|---|---|---|
| `#id` | `String` | Practice identifier (e.g. `"practice-125055"`). |
| `#address` | `String` | Street address. |
| `#zipcode` | `String` | Postal code. |
| `#city` | `String` | City name. |
| `#full_address` | `String` | Combined address string. |
| `#landline_number` | `String \| nil` | Phone number, if available. |
| `#latitude` | `Float` | Latitude. |
| `#longitude` | `Float` | Longitude. |
| `#elevator` | `Boolean` | Whether the practice has elevator access. |
| `#handicap` | `Boolean` | Whether the practice is handicap-accessible. |
| `#formal_name` | `String \| nil` | Formal practice name, if available. |
| `#coordinates` | `Array<Float>` | Convenience method returning `[latitude, longitude]`. |

### `TocDoc::BookingInfo`

Returned by `TocDoc::BookingInfo.find`; also accessible via the `TocDoc.booking_info` module-level shortcut.

| Method | Type | Description |
|---|---|---|
| `#profile` | `Profile::Practitioner \| Profile::Organization` | Typed profile built via `Profile.build`. |
| `#specialities` | `Array<TocDoc::Speciality>` | Specialities associated with the booking context. |
| `#visit_motives` | `Array<TocDoc::VisitMotive>` | Available visit motives (reasons for consultation). |
| `#agendas` | `Array<TocDoc::Agenda>` | Agendas, each pre-resolved with their matching `VisitMotive` objects. |
| `#places` | `Array<TocDoc::Place>` | Practice locations. |
| `#practitioners` | `Array<TocDoc::Profile::Practitioner>` | Practitioners associated with this booking context (`partial: true`). |
| `#organization?` | `Boolean` | Delegates to the inner profile. |

### `TocDoc::VisitMotive`

Represents a visit motive (reason for consultation) returned inside a `BookingInfo` response. Inherits dot-notation attribute access from `TocDoc::Resource`.

| Method | Type | Description |
|---|---|---|
| `#id` | `Integer` | Visit motive identifier. |
| `#name` | `String` | Human-readable name of the visit motive. |

### `TocDoc::Agenda`

Represents an agenda (calendar) returned inside a `BookingInfo` response. Inherits dot-notation attribute access from `TocDoc::Resource`.

| Method | Type | Description |
|---|---|---|
| `#id` | `Integer` | Agenda identifier. |
| `#practice_id` | `Integer` | ID of the associated practice. |
| `#visit_motives` | `Array<TocDoc::VisitMotive>` | Visit motives pre-resolved via `visit_motive_ids` when built through `BookingInfo`. |

### `TocDoc::Speciality`

Represents a speciality returned by the autocomplete endpoint. Inherits dot-notation attribute access from `TocDoc::Resource`.

| Method | Type | Description |
|---|---|---|
| `#value` | `Integer` | Numeric speciality identifier. |
| `#slug` | `String` | URL-friendly identifier. |
| `#name` | `String` | Human-readable speciality name. |

**Example:**

```ruby
result = TocDoc::Search.where(query: 'dermato')

result.profiles.first.class          # => TocDoc::Profile::Practitioner
result.profiles.first.practitioner?  # => true
result.profiles.first.name           # => "Dr. Jane Smith"

result.specialities.first.slug   # => "dermatologue"
result.specialities.first.name   # => "Dermatologue"
```

---

## Pagination

The Doctolib availability endpoint is window-based: each request returns up to
`limit` dates starting from `start_date`.

### Automatic next-slot resolution

`TocDoc::Availability.where` automatically follows `next_slot` once: if the
first API response contains a `next_slot` key (indicating no available slots in
the requested window), a second request is issued transparently from that date
before the collection is returned.

### Manual window advancement

To fetch additional date windows, call `TocDoc::Availability.where` again with a
later `start_date`:

```ruby
first_page = TocDoc::Availability.where(
  visit_motive_ids: 7_767_829,
  agenda_ids:       1_101_600,
  start_date:       Date.today
)

if first_page.any?
  next_start = first_page.raw_availabilities.last.date + 1
  next_page  = TocDoc::Availability.where(
    visit_motive_ids: 7_767_829,
    agenda_ids:       1_101_600,
    start_date:       next_start
  )
end
```

---

## Error handling

All errors raised by TocDoc inherit from `TocDoc::Error < StandardError`,
so you can rescue the whole hierarchy with a single clause:

```ruby
begin
  TocDoc::Availability.where(visit_motive_ids: 0, agenda_ids: 0)
rescue TocDoc::Error => e
  puts "Doctolib error: #{e.message}"
end
```

The default middleware stack also includes `Faraday::Response::RaiseError` for
HTTP-level failures, and a `Faraday::Retry::Middleware` that automatically
retries (up to 3 times, with exponential back-off) on:

- `429 Too Many Requests`
- `500 Internal Server Error`
- `502 Bad Gateway`
- `503 Service Unavailable`
- `504 Gateway Timeout`
- network timeouts

---

## Development

Clone the repository and install dependencies:

```bash
git clone https://github.com/01max/toc_doc.git
cd toc_doc
bin/setup
```

Run the test suite:

```bash
bundle exec rake spec
# or
bundle exec rspec
```

Run the linter:

```bash
bundle exec rubocop
```

Open an interactive console with the gem loaded:

```bash
bin/console
```

Install the gem locally:

```bash
bundle exec rake install
```

### Adding new endpoints

1. Create `lib/toc_doc/models/<resource>.rb` with a model class inheriting from
   `TocDoc::Resource`. Add a class-level `.where` (or equivalent) query method
   that calls `TocDoc.client.get` / `.post` to issue requests.
2. If the endpoint is paginated, create
   `lib/toc_doc/models/<resource>/collection.rb` with an `Enumerable` collection
   class (see `TocDoc::Availability::Collection` for the pattern).
3. Require the new files from `lib/toc_doc/models.rb`.
4. Add specs under `spec/toc_doc/models/`.

### Generating documentation

The codebase uses [YARD](https://yardoc.org/) for API documentation. All public
methods are annotated with `@param`, `@return`, and `@example` tags.

Generate the HTML docs:

```bash
bundle exec yard doc
```

The output is written to `doc/`. To browse it locally:

```bash
bundle exec yard server
# → http://localhost:8808
```

To check documentation coverage without generating files:

```bash
bundle exec yard stats
```

---

## Contributing

Bug reports and pull requests are welcome on GitHub at
<https://github.com/01max/toc_doc>. This project is intended to be a safe,
welcoming space for collaboration, and contributors are expected to adhere to
the [code of conduct](https://github.com/01max/toc_doc/blob/main/CODE_OF_CONDUCT.md).

---

## Code of Conduct

Everyone interacting in the TocDoc project's codebases, issue trackers, chat
rooms and mailing lists is expected to follow the
[code of conduct](https://github.com/01max/toc_doc/blob/main/CODE_OF_CONDUCT.md).

---

## License

The gem is available as open source under the terms of the
[GNU General Public v3 License](LICENSE.md).
