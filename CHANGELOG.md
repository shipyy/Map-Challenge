# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.3.1]

### Changed

- Updated `surftimer.inc`

### Fixed

- Wrong forward function

**Full Changelog**: https://github.com/shipyy/Map-Challenge/compare/v2.3.1...v2.3.1

## [2.3.0]

### Added

- Added a `sql` file with a clean install for all the tables

### Fixed

- Fixed wrong query for creating a table
- Wrong phrase for `/style_acronyms`

**Full Changelog**: https://github.com/shipyy/Map-Challenge/compare/v2.3.0...v2.2.0

## [2.2.0]

### Changed

- Re-did some section of `README`

### Added

- Added time prefixes (d, h and m)
- Added translation with Winner's name
- Added command to display the available time prefixes

### Fixed

- Fixed some some translations displaying wrong info

**Full Changelog**: https://github.com/shipyy/Map-Challenge/compare/v2.2.0...v2.1.0

## [2.0.3]

### Fixed

- Points distribuition would sometimes not give correct value (i.e : would give `49` instead of `50` points because of some `float` to `int` conversions)

**Full Changelog**: https://github.com/shipyy/Map-Challenge/compare/v2.0.2...v2.0.3

## [2.0.2]

### Added

- ConVar to change prefix in chat

### Fixed

- Translation file to reflect prefix change

**Full Changelog**: https://github.com/shipyy/Map-Challenge/compare/v2.0.1...v2.0.2

## [2.0.1]

### Added

- Workflow Actions.

**Full Changelog**: https://github.com/shipyy/Map-Challenge/compare/v2.0.0...v2.0.1

## [2.0.0]

### Changed

- Make MapChallenge not a required plugin.
- Logic for detecting `challenge_active` `challenge_end` and `challenge_timeleft` revamped.
- Every `TIMESTAMP` related code is now all in `UTC`.
- Improve translations.
- Top10 points are now percentile based - i.e:
    - _Rank 1_ - 1000 points
    - _Rank 1_ - 90% of Rank1 points
    - _Rank 3_ - 80% of Rank1 points

### Fixed

- Plugin will now work when being used by mulitple servers.
- Distribuition of points would insert negative values whenver challenge rank1 points were `<1000`.
- Wrong client to print message when a player would improve their Challenge PR.