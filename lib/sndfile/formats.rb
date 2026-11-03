# frozen_string_literal: true

module SndFile
  # A format libsndfile supports, as listed by SndFile.major_formats,
  # SndFile.subtypes and SndFile.simple_formats: its Format, a description
  # and (for major and simple formats) the usual file extension.
  FormatDescription = Data.define(:format, :name, :extension)

  # Lists the formats the loaded libsndfile supports, using its
  # SFC_GET_FORMAT_* commands.
  module Formats
    # The major formats (containers), e.g. "WAV (Microsoft)".
    def self.major_formats
      list(SFC_GET_FORMAT_MAJOR_COUNT, SFC_GET_FORMAT_MAJOR)
    end

    # The subtypes (encodings), e.g. "Signed 16 bit PCM".
    def self.subtypes
      list(SFC_GET_FORMAT_SUBTYPE_COUNT, SFC_GET_FORMAT_SUBTYPE)
    end

    # Common combinations of major format and subtype.
    def self.simple_formats
      list(SFC_GET_SIMPLE_FORMAT_COUNT, SFC_GET_SIMPLE_FORMAT)
    end

    # The description of one format (SFC_GET_FORMAT_INFO), or nil when
    # libsndfile doesn't know it. Takes a major format or a subtype alone,
    # as an integer or anything Format.coerce accepts.
    def self.describe(format)
      code = format.is_a?(Symbol) ? symbol_code(format) : Format.coerce(format).to_i
      info = Native::FormatInfo.new
      info[:format] = code
      return unless Native.sf_command(nil, SFC_GET_FORMAT_INFO, info, info.size).zero?

      description(info)
    end

    def self.list(count_command, item_command)
      count = FFI::MemoryPointer.new(:int)
      Native.sf_command(nil, count_command, count, count.size)
      Array.new(count.read_int) do |index|
        info = Native::FormatInfo.new
        info[:format] = index
        Native.sf_command(nil, item_command, info, info.size)
        description(info)
      end
    end

    def self.description(info)
      FormatDescription.new(format: Format.new(info[:format]), name: info[:name], extension: info[:extension])
    end

    def self.symbol_code(symbol)
      Native.enum_type(:sf_major_format)[symbol] || Native.enum_type(:sf_subtype)[symbol] or
        raise ArgumentError, "Unknown format #{symbol.inspect}"
    end
    private_class_method :list, :description, :symbol_code
  end
end
