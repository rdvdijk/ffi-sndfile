# Contributing to ffi-sndfile

## Setup

You need libsndfile 1.0.28 or newer with its development files (see [Requirements](README.md#requirements) in the README), and the Ruby version from `.ruby-version` (3.4.12). Most Ruby version managers (such as chruby, rbenv, asdf or mise) pick that file up. Then install the dependencies:

```bash
bundle install
```

## Commands

| Command | What it does |
|---|---|
| `bundle exec rake` | Runs all specs and RuboCop |
| `bundle exec rspec` | Runs all specs (unit and integration) |
| `bundle exec rake spec:integration` | Runs only the integration specs (see below) |
| `bundle exec rubocop` | Lints the code (`-a` fixes what it safely can) |
| `COVERAGE=1 bundle exec rspec` | Also writes a coverage report to `coverage/lcov.info` |

Before you open a pull request, `bundle exec rake` should pass without failures or RuboCop offenses.

## Supported Ruby versions

Changes must work on every Ruby version that the [CI workflow](.github/workflows/ci.yml) tests: currently Ruby 3.2, 3.3, 3.4 and 4.0. The gemspec requires Ruby 3.2 or newer, so don't use language features or standard library methods that are newer than that, and don't write specs that depend on the output format of one Ruby version (Ruby 3.4, for example, changed `Hash#inspect`).

CI also runs the specs on ruby-head, JRuby and TruffleRuby. Failures there don't fail the workflow, but please keep them passing where you can.

To check another Ruby version locally, switch to it with your Ruby version manager, then install the dependencies and run the specs:

```bash
bundle install
bundle exec rspec
```

`Gemfile.lock` is committed and resolved on Ruby 3.2, the oldest supported version, so every tested Ruby version can install it. When you add or update a gem, resolve it on Ruby 3.2 too: on a newer Ruby, Bundler may pick versions that Ruby 3.2 can't install. Dependabot proposes weekly updates, and CI checks them on all Ruby versions.

## The integration specs

The integration specs (`spec/integration`) write real audio files to a temporary directory and read them back. Unlike the unit specs they test whole workflows, but they need nothing beyond libsndfile, so `bundle exec rspec` runs them too.

- `ogg_vorbis_spec.rb` writes Ogg/Vorbis files with Vorbis comments. It checks them with `spec/lib/ogg_vorbis_reader.rb`, a small Ogg/Vorbis parser that doesn't use libsndfile (it verifies every page's CRC and decodes the identification and comment headers), and by reading them back through the gem. If `vorbiscomment` from vorbis-tools is installed (`sudo apt-get install vorbis-tools`), it also checks the comments with that; otherwise that example is skipped. The specs are skipped when libsndfile was built without Ogg/Vorbis support.
- `round_trip_spec.rb` checks that lossless formats (WAV, AIFF, FLAC, CAF, ...) give back exactly the samples that were written.

## Code layout

- `lib/sndfile/native.rb` and `lib/sndfile/native/` hold the libsndfile bindings: `SndFile::Native` is the `FFI::Library` with an `attach_function` for every function in `sndfile.h` (`functions.rb`), an `FFI::Struct` for every struct (`structs.rb`) and FFI enums for the constants (`enums.rb`). Keep these declarations in the order of `sndfile.h`, with the comments from that header. `lib/sndfile/constants.rb` has every constant of `sndfile.h`, also with its comments.
- The struct sizes and offsets in `spec/sndfile/native_structs_spec.rb` come from a C program compiled against `sndfile.h` on x86_64 Linux. When you add or change a struct, check it the same way: print `sizeof` and `offsetof` for it in C and compare.
- The rest of `lib/sndfile/` is the Ruby API (`SoundFile`, `Format`, `Strings`, `VirtualIO`, the error classes) built on top of `SndFile::Native`.
- Specs mirror `lib/` under `spec/sndfile/`.

## Changelog

Describe user-visible changes in [CHANGELOG.md](CHANGELOG.md).
