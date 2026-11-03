# frozen_string_literal: true

module SndFile
  # The version of the loaded libsndfile library (sf_version_string), as
  # returned by SndFile.version.
  class LibraryVersion
    include Comparable

    # The oldest libsndfile with every function these bindings attach.
    # Some sf_command commands are newer: the MPEG formats and
    # SFC_GET/SET_BITRATE_MODE need 1.1.0.
    MINIMUM = "1.0.28"

    attr_reader :string, :major, :minor, :patch

    # Raises LoadError when the loaded libsndfile is older than MINIMUM.
    def self.ensure_supported!
      version = new
      return version if version >= MINIMUM

      raise LoadError, "ffi-sndfile needs libsndfile #{MINIMUM} or newer, but found #{version.number}"
    end

    # Parses a version string such as "libsndfile-1.2.2" (the default is the
    # loaded library's).
    def initialize(string = Native.sf_version_string)
      @string = string
      match = string.to_s.match(/(\d+)\.(\d+)\.(\d+)/)
      raise ArgumentError, "Cannot parse libsndfile version #{string.inspect}" unless match

      @major, @minor, @patch = match.captures.map(&:to_i)
    end

    # "major.minor.patch", e.g. "1.2.2".
    def number
      [major, minor, patch].join(".")
    end

    def <=>(other)
      other = other.number if other.is_a?(LibraryVersion)
      Gem::Version.new(number) <=> Gem::Version.new(other.to_s)
    end

    def to_s
      @string
    end

    def inspect
      "#<#{self.class.name} #{number}>"
    end
  end
end
