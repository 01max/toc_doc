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
- [x] Error base class & factory
- [x] Error subclasses (4xx/5xx)
- [x] RaiseError middleware
- [x] Error mapping specs

## 5 – Client & Availabilities
- [x] Client includes config + connection
- [x] Availabilities endpoint module
- [x] TocDoc.availabilities delegation
- [x] Availabilities specs (stubs/VCR)

## 6 – Response Objects
- [x] Resource wrapper
- [x] Availability objects
- [x] Client mapping to response objects
- [x] Response specs

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