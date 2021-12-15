# Changelog
All notable changes to this project will be documented in this file.

Version format based on http://semver.org/

## [Unreleased]

## [0.2.1] - 2021-12-15

## Fixed
- `filtergroup` and `filtername` paramters to pkg_query made optional. (the puppet fact does not pass them)
## [0.2.0] - 2021-09-03

## Added
- `--filtergroup` and `--filtername` options to provide extra filtering on queried packages as `--query` does not provide exact matches.

## [0.1.2] - 2019-07-05
## Changed
- immediately stop retries when the given address is not available
- added `max_retries` and `retry_timeout` options while keeping the current defaults

## [0.1.1] - 2018-01-30
## Added
- retry failed get

## [0.1.0] - 2018-01-30
## Added
- First working version
