# frozen_string_literal: true

module SndFile
  # A libsndfile format: a major format (the container, such as :ogg), a
  # subtype (the encoding, such as :vorbis) and an endianness. libsndfile
  # ORs these together into one integer, which #to_i returns.
  class Format
    # The subtype used when only a major format is given.
    DEFAULT_SUBTYPES = {
      wav: :pcm_16, wavex: :pcm_16, aiff: :pcm_16, au: :pcm_16, raw: :pcm_16,
      w64: :pcm_16, caf: :pcm_16, rf64: :pcm_16, flac: :pcm_16,
      ogg: :vorbis, mpeg: :mpeg_layer_iii
    }.freeze

    # Formats for common file name extensions, used by Format.for_path.
    EXTENSIONS = {
      "wav" => [:wav], "aif" => [:aiff], "aiff" => [:aiff], "aifc" => [:aiff],
      "au" => [:au], "snd" => [:au], "raw" => [:raw], "w64" => [:w64],
      "caf" => [:caf], "rf64" => [:rf64], "flac" => [:flac],
      "ogg" => %i[ogg vorbis], "oga" => %i[ogg vorbis], "opus" => %i[ogg opus],
      "mp3" => %i[mpeg mpeg_layer_iii]
    }.freeze

    # Converts +value+ (a Format, an Integer, a major format Symbol or an
    # Array such as [:ogg, :vorbis]) to a Format.
    def self.coerce(value, subtype = nil, endian = nil)
      case value
      when Format then value
      when Integer then new(value)
      when Symbol, String then new(value, subtype, endian || :file)
      when Array then new(*value)
      else raise ArgumentError, "Expected a Format, Integer, Symbol or Array, got #{value.class}"
      end
    end

    # The format for a file name's extension, or nil for unknown extensions.
    def self.for_path(path)
      extension = ::File.extname(path.to_s).delete_prefix(".").downcase
      EXTENSIONS[extension]&.then { |args| new(*args) }
    end

    # Builds a format from a major format and subtype (symbols or integer
    # constants), or from a complete format integer.
    def initialize(major, subtype = nil, endian = :file)
      @to_i = if major.is_a?(Integer) && subtype.nil?
                major
              else
                major_code = code(:sf_major_format, major)
                subtype ||= default_subtype(major_code)
                major_code | code(:sf_subtype, subtype) | code(:sf_endian, endian)
              end
      freeze
    end

    attr_reader :to_i
    alias to_int to_i

    # The major format, as a symbol such as :wav (or the integer if unknown).
    def major
      symbol(:sf_major_format, to_i & SF_FORMAT_TYPEMASK)
    end

    # The subtype, as a symbol such as :pcm_16 (or the integer if unknown).
    def subtype
      symbol(:sf_subtype, to_i & SF_FORMAT_SUBMASK)
    end

    # The endianness: :file, :little, :big or :cpu.
    def endian
      symbol(:sf_endian, to_i & SF_FORMAT_ENDMASK)
    end

    # Whether libsndfile can write this format with the given sample rate
    # and channel count (sf_format_check).
    def valid?(samplerate:, channels:)
      info = Native::Info.new
      info[:format] = to_i
      info[:samplerate] = samplerate
      info[:channels] = channels
      Native.sf_format_check(info) == SF_TRUE
    end

    def ==(other)
      other.is_a?(Format) && to_i == other.to_i
    end
    alias eql? ==

    def hash
      [self.class, to_i].hash
    end

    # "ogg/vorbis", "wav/pcm_16/big", or just "flac" for a format without a
    # subtype (as in the Formats listings).
    def to_s
      parts = [major, subtype].reject { |part| part.equal?(0) }
      parts << endian unless endian == :file
      parts.join("/")
    end

    def inspect
      "#<#{self.class.name} #{self}>"
    end

    private

    def code(enum_name, value)
      return value if value.is_a?(Integer)

      enum = Native.enum_type(enum_name)
      enum[value.to_s.downcase.to_sym] or
        raise ArgumentError, "Unknown #{enum_name.to_s.delete_prefix("sf_").tr("_", " ")}: #{value.inspect}"
    end

    def default_subtype(major_code)
      DEFAULT_SUBTYPES.fetch(Native.enum_type(:sf_major_format)[major_code]) do
        raise ArgumentError, "A subtype is needed for #{symbol(:sf_major_format, major_code).inspect} files"
      end
    end

    def symbol(enum_name, value)
      Native.enum_type(enum_name)[value] || value
    end
  end
end
