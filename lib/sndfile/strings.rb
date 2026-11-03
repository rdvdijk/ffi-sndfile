# frozen_string_literal: true

module SndFile
  # The string metadata of a sound file, such as its title and artist
  # (sf_get_string / sf_set_string). libsndfile stores them as the format's
  # own tags: Vorbis comments in Ogg and FLAC, the INFO chunk in WAV. Most
  # formats need them set before any audio is written.
  class Strings
    include Enumerable

    # The string types, in libsndfile's order (SF_STR_*).
    NAMES = Native.enum_type(:sf_str).symbols.freeze

    def initialize(sound_file)
      @sound_file = sound_file
    end

    # The string +name+ (one of NAMES), or nil when the file has none. It is
    # returned as UTF-8, or as binary when it isn't valid UTF-8.
    def [](name)
      value = Native.sf_get_string(@sound_file.handle, name_for(name))
      return if value.nil?

      utf8 = value.dup.force_encoding(Encoding::UTF_8)
      utf8.valid_encoding? ? utf8 : value
    end

    # Sets the string +name+ (one of NAMES). Raises a SndFileError when the
    # file format doesn't support it or audio data was already written.
    def []=(name, value)
      handle = @sound_file.handle
      Error.check_error(Native.sf_set_string(handle, name_for(name), value.to_s.encode(Encoding::UTF_8)), handle)
    end

    NAMES.each do |name|
      define_method(name) { self[name] }
      define_method(:"#{name}=") { |value| self[name] = value }
    end
    alias track_number tracknumber
    alias track_number= tracknumber=

    # Sets every string in +hash+, e.g. update(title: "Song", artist: "Me").
    def update(hash)
      hash.each { |name, value| self[name] = value }
      self
    end

    # Yields each string that is set, as name and value.
    def each(&)
      return enum_for(:each) unless block_given?

      to_h.each(&)
      self
    end

    def to_h
      NAMES.filter_map { |name| (value = self[name]) && [name, value] }.to_h
    end

    def inspect
      "#<#{self.class.name} #{to_h.inspect}>"
    end

    private

    def name_for(name)
      symbol = name.to_s.downcase.to_sym
      symbol = :tracknumber if symbol == :track_number
      return symbol if NAMES.include?(symbol)

      raise ArgumentError, "Unknown string #{name.inspect}; expected one of #{NAMES.join(", ")}"
    end
  end
end
