# frozen_string_literal: true

require "ffi"
require "sndfile/version"
require "sndfile/constants"
require "sndfile/error"
require "sndfile/native"
require "sndfile/format"
require "sndfile/info"
require "sndfile/formats"
require "sndfile/strings"
require "sndfile/virtual_io"
require "sndfile/commands"
require "sndfile/sound_file"

# Ruby bindings for libsndfile, the library for reading and writing sound
# files. Start with SndFile::SoundFile (or SndFile.open); the raw libsndfile
# functions live in SndFile::Native.
module SndFile
  # The version of the loaded libsndfile library.
  def self.version
    LibraryVersion.new
  end

  # Same as SoundFile.open.
  def self.open(target, mode = :read, **, &)
    SoundFile.open(target, mode, **, &)
  end

  # The major formats (containers) libsndfile supports; see Formats.
  def self.major_formats
    Formats.major_formats
  end

  # The subtypes (encodings) libsndfile supports; see Formats.
  def self.subtypes
    Formats.subtypes
  end

  # Common combinations of major format and subtype; see Formats.
  def self.simple_formats
    Formats.simple_formats
  end
end
