# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

<!--
  These ARE the release notes. One short line per entry, written for a user of the
  modules. CI-only, test-only and docs-only PRs take the `no changelog` label.
-->


## [Unreleased]

## [0.0.3] - 2026-10-12

### Added

- `spec.name` on every CRD: the entry's cn (uid for a ServiceAccount), defaulting to `metadata.name`, so two resources can name the same entry under different base DNs.

## [0.0.2] - 2026-10-12

### Added

- `service-account` module: a principal with its primary `gidNumber` and a generated or supplied password.
- `group` module: a posix group for the unix plane, with a curated member list.
- `team` module: a cohort of people; structure only, membership is filled externally.
- `role` module: a realm-wide capability whose member list terraform owns.
- `client` module: an app's login surface, its client roles as children; structure only.
- Crossplane CRDs for each kind (`*.ldap.kubed.io`), pinned to the release's own modules and pulled once per release.
