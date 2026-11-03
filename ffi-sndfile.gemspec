# frozen_string_literal: true

require_relative "lib/sndfile/version"

Gem::Specification.new do |spec|
  spec.name          = "ffi-sndfile"
  spec.version       = SndFile::VERSION
  spec.authors       = ["Roel van Dijk"]
  spec.email         = ["roel@rustradio.org"]

  spec.summary       = "Read and write WAV, FLAC, Ogg/Vorbis, Opus, MP3 and other audio files using libsndfile."
  spec.description   = "Ruby FFI wrapper around libsndfile for reading and writing sound files."
  spec.homepage      = "https://github.com/rdvdijk/ffi-sndfile"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 3.2"

  spec.metadata["source_code_uri"]       = spec.homepage
  spec.metadata["bug_tracker_uri"]       = "#{spec.homepage}/issues"
  spec.metadata["changelog_uri"]         = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files         = Dir["lib/**/*.rb", "CHANGELOG.md", "LICENSE.txt", "README.md"]
  spec.require_paths = ["lib"]

  spec.add_dependency "ffi", "~> 1.15"
end
