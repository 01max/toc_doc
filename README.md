# TocDoc

A Ruby gem for interacting with the (unofficial) Doctolib API. A thin, Faraday-based client with modular resource endpoints, configurable defaults, optional auto-pagination, and a clean error hierarchy.

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

# Use the pre-configured module-level client …
response = TocDoc.availabilities(
  visit_motive_ids: 7_767_829,
  agenda_ids:       1_101_600,
  practice_ids:     377_272,
  telehealth:       false
)

response.total      # => 5
response.next_slot  # => "2026-02-28T10:00:00.000+01:00"

response.availabilities.each do |avail|
  puts "#{avail.date}: #{avail.slots.join(', ')}"
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

TocDoc.availabilities(visit_motive_ids: 123, agenda_ids: 456)
```

Calling `TocDoc.reset!` restores all options to their defaults.  
Use `TocDoc.options` to inspect the current configuration hash.

### Per-client configuration

Instantiate independent clients with different options:

```ruby
de_client = TocDoc::Client.new(api_endpoint: 'https://www.doctolib.de')
it_client = TocDoc::Client.new(api_endpoint: 'https://www.doctolib.it', per_page: 3)

de_client.availabilities(visit_motive_ids: 123, agenda_ids: 456)
it_client.availabilities(visit_motive_ids: 789, agenda_ids: 101)
```

### All configuration options

| Option | Default | Description |
|---|---|---|
| `api_endpoint` | `https://www.doctolib.fr` | Base URL. Change to `.de` / `.it` for other countries. |
| `user_agent` | `TocDoc Ruby Gem 0.1.0` | `User-Agent` header sent with every request. |
| `default_media_type` | `application/json` | `Accept` and `Content-Type` headers. |
| `per_page` | `5` | Default number of results returned per request, platform's max is currently at `15`. |
| `auto_paginate` | `false` | When `true`, automatically fetches all pages and merges results. |
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
| `TOCDOC_AUTO_PAGINATE` | `auto_paginate` (`"true"` / anything else) |
| `TOCDOC_RETRY_MAX` | Maximum Faraday retry attempts (default `3`) |

---

## Endpoints

### Availabilities

Retrieve open appointment slots for a given visit motive and agenda.

```ruby
client.availabilities(
  visit_motive_ids: visit_motive_id,   # Integer, String, or Array
  agenda_ids:       agenda_id,         # Integer, String, or Array
  start_date:       Date.today,        # Date or String (default: today)
  limit:            5,                 # override per_page for this call
  # any extra keyword args are forwarded verbatim as query params:
  practice_ids:     377_272,
  telehealth:       false
)
```

**Multiple IDs** are accepted as arrays; the gem serialises them with the
dash-separated format Doctolib expects:

```ruby
client.availabilities(
  visit_motive_ids: [7_767_829, 7_767_830],
  agenda_ids:       [1_101_600, 1_101_601]
)
# → GET /availabilities.json?visit_motive_ids=7767829-7767830&agenda_ids=1101600-1101601&…
```

**Return value:** a `TocDoc::Response::Availability` (see [Response objects](#response-objects)).

---

## Response objects

All API responses are wrapped in lightweight Ruby objects that provide
dot-notation access and a `#to_h` round-trip helper.

### `TocDoc::Response::Availability`

Returned by `#availabilities`.

| Method | Type | Description |
|---|---|---|
| `#total` | `Integer` | Total number of available slots across all dates. |
| `#next_slot` | `String \| nil` | ISO 8601 datetime of the nearest available slot. `nil` when none remain. |
| `#availabilities` | `Array<TocDoc::Availability>` | One entry per date. |
| `#to_h` | `Hash` | Plain-hash representation including expanded availability entries. |

### `TocDoc::Availability`

Each element of `Response::Availability#availabilities`.

| Method | Type | Description |
|---|---|---|
| `#date` | `String` | Date in `YYYY-MM-DD` format. |
| `#slots` | `Array<String>` | ISO 8601 datetimes for each bookable slot on that date. |
| `#to_h` | `Hash` | Plain-hash representation. |

**Example:**

```ruby
response = TocDoc.availabilities(visit_motive_ids: 123, agenda_ids: 456)

response.total      # => 5
response.next_slot  # => "2026-02-28T10:00:00.000+01:00"

response.availabilities.first.date   # => "2026-02-28"
response.availabilities.first.slots  # => ["2026-02-28T10:00:00.000+01:00", ...]

response.to_h
# => {
#      "total"          => 5,
#      "next_slot"      => "2026-02-28T10:00:00.000+01:00",
#      "availabilities" => [{ "date" => "2026-02-28", "slots" => [...] }, ...]
#    }
```

---

## Pagination

The Doctolib availability endpoint is paginated by `start_date` and `limit`.
TocDoc can manage this automatically.

### Automatic pagination

Set `auto_paginate: true` on the client (or at module level) to fetch all pages
and have results merged into a single `Response::Availability` object:

```ruby
client = TocDoc::Client.new(auto_paginate: true, per_page: 5)

all_slots = client.availabilities(
  visit_motive_ids: 7_767_829,
  agenda_ids:       1_101_600,
  start_date:       Date.today
)

all_slots.total             # total across every page
all_slots.availabilities    # every date entry, concatenated
```

Pagination stops automatically when the API returns `next_slot: null`.

### Module-level toggle

```ruby
TocDoc.configure { |c| c.auto_paginate = true }

TocDoc.availabilities(visit_motive_ids: 123, agenda_ids: 456)
```

---

## Error handling

All errors raised by TocDoc inherit from `TocDoc::Error < StandardError`,
so you can rescue the whole hierarchy with a single clause:

```ruby
begin
  TocDoc.availabilities(visit_motive_ids: 0, agenda_ids: 0)
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

1. Create `lib/toc_doc/client/<resource>.rb` and define a module
   `TocDoc::Client::<Resource>` with your endpoint methods.
2. Call `get`/`post`/`paginate` (from `TocDoc::Connection`) to issue requests.
3. Create `lib/toc_doc/models/response/<resource>.rb` (and any model classes)
   inheriting from `TocDoc::Resource`.
4. Include the new module in `TocDoc::Client` (`lib/toc_doc/client.rb`).
5. Add corresponding specs under `spec/toc_doc/client/`.

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
