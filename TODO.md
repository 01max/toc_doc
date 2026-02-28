# 1.0

## 1 – Skeleton & Tooling
- [x] Scaffold gem & layout
- [x] Gem spec metadata & deps
- [x] Lib structure (default/config/client/etc.)
- [x] CI workflow (RSpec + RuboCop)
- [x] RSpec + WebMock + VCR setup

## 2 – Configuration
- [x] Default options & ENV fallbacks
- [x] Configurable module (keys, reset, options)
- [x] Top-level TocDoc wiring (client, setup, delegation)
- [x] Config specs (module + client)

## 3 – Connection & HTTP
- [x] Connection module (agent, request helpers)
- [x] ~Faraday middleware~
- [x] URL building helpers
- [x] Connection specs

## 4 – Error Handling
- [ ] Error base class & factory
- [ ] Error subclasses (4xx/5xx)
- [ ] RaiseError middleware
- [ ] Error mapping specs

## 5 – Client & Availabilities
- [ ] Client includes config + connection
- [ ] Availabilities endpoint module
- [ ] TocDoc.availabilities delegation
- [ ] Availabilities specs (stubs/VCR)

## 6 – Response Objects
- [ ] Resource wrapper
- [ ] Availability objects
- [ ] Client mapping to response objects
- [ ] Response specs

## 8 – Pagination
- [ ] Analyze pagination model
- [ ] Implement Connection#paginate
- [ ] Pagination config & specs

## 9 – Docs & Release
- [ ] README
- [ ] YARD docs
- [ ] CHANGELOG
- [ ] Build & publish gem 
  - [ ] on rubygem
  - [ ] gem.coop ?

# 1.1

## Better API usage
- [ ] Rate limiting
- [ ] Caching
- [ ] Logging
- [ ] Better multi-region support ?
- [ ] Async support ?

## Extra Endpoints
- [ ] Identify additional endpoints
- [ ] Implement resource modules
- [ ] Specs per endpoint

# 1.2

## Auth / User-based actions
- [ ] Research auth scheme
- [ ] Authentication module + headers
- [ ] Auth specs