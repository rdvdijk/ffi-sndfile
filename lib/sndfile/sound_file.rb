# frozen_string_literal: true

module SndFile
  # A sound file opened for reading, writing or both.
  #
  # Samples are flat Arrays with the channels interleaved: left, right, left,
  # right, ... for stereo. They are :float (the default, -1.0..1.0), :double,
  # :short or :int; libsndfile converts them from and to the file's encoding.
  class SoundFile
    include Commands

    SAMPLE_TYPES = { short: :short, int: :int, float: :float, double: :double }.freeze

    # Frames per read in #each_buffer and #read without a frame count.
    DEFAULT_BUFFER_FRAMES = 4096

    # The path, or the IO object for files opened through VirtualIO.
    attr_reader :target

    # :read, :write or :rdwr.
    attr_reader :mode

    # Opens a sound file. Without a block, returns the SoundFile. With a
    # block, yields it, closes it afterwards (also when the block raises)
    # and returns the block's value.
    def self.open(target, mode = :read, **, &)
      file = new(target, mode, **)
      return file unless block_given?

      begin
        yield file
      ensure
        file.close
      end
    end

    # Opens +target+, a path or an IO-like object (see VirtualIO), in +mode+
    # :read, :write or :rdwr.
    #
    # Writing needs +samplerate+, +channels+ and a +format+: anything
    # Format.coerce accepts, with an optional +subtype+ and +endian+. Without
    # a format, it follows the path's extension. Reading RAW files needs the
    # same options. +strings+ are set before any audio is written.
    def initialize(target, mode = :read, format: nil, subtype: nil, endian: nil, samplerate: nil, channels: nil,
                   strings: nil)
      @target = target
      @mode = Native.enum_type(:sf_mode).find(Native.enum_type(:sf_mode).to_native(mode, nil))
      info = native_info(format_for(format, subtype, endian), samplerate, channels)
      @handle = open_handle(target, info)
      self.strings.update(strings) if strings
    end

    # The file's current Info (SFC_GET_CURRENT_SF_INFO), which includes the
    # frames written so far.
    def info
      struct = Native::Info.new
      command(SFC_GET_CURRENT_SF_INFO, struct)
      Info.from_native(struct)
    end

    def frames = info.frames
    def samplerate = info.samplerate
    def channels = info.channels
    def format = info.format
    def sections = info.sections
    def seekable? = info.seekable?
    def duration = info.duration

    # The string metadata (title, artist, ...); see Strings.
    def strings
      @strings ||= Strings.new(self)
    end

    # The current byte rate (bytes of audio per second), or nil if unknown.
    def byterate
      rate = Native.sf_current_byterate(handle)
      rate unless rate.negative?
    end

    # Reads up to +frames+ frames and returns their samples as a flat,
    # interleaved Array (empty at the end of the file). Without +frames+,
    # reads everything up to the end of the file.
    def read(frames = nil, type: :float)
      return read_all(type) if frames.nil?

      ffi_type = ffi_type_for(type)
      channel_count = channels
      buffer = FFI::MemoryPointer.new(ffi_type, frames * channel_count)
      read_frames = Native.public_send(:"sf_readf_#{type}", handle, buffer, frames)
      check_io!
      buffer.public_send(:"get_array_of_#{ffi_type}", 0, read_frames * channel_count)
    end

    # Yields the samples of each buffer of up to +frames+ frames until the
    # end of the file. Returns an Enumerator without a block.
    def each_buffer(frames = DEFAULT_BUFFER_FRAMES, type: :float)
      return enum_for(:each_buffer, frames, type: type) unless block_given?

      loop do
        samples = read(frames, type: type)
        break if samples.empty?

        yield samples
      end
      self
    end

    # Reads up to +bytes+ bytes of the encoded audio data (sf_read_raw).
    def read_raw(bytes)
      buffer = FFI::MemoryPointer.new(:char, bytes)
      count = Native.sf_read_raw(handle, buffer, bytes)
      check_io!
      buffer.get_bytes(0, count)
    end

    # Writes +samples+, a flat interleaved Array whose size is a multiple of
    # the channel count. Returns the number of frames written.
    def write(samples, type: :float)
      ffi_type = ffi_type_for(type)
      frames = frame_count(samples)
      return 0 if frames.zero?

      buffer = FFI::MemoryPointer.new(ffi_type, samples.size)
      buffer.public_send(:"put_array_of_#{ffi_type}", 0, samples)
      written = Native.public_send(:"sf_writef_#{type}", handle, buffer, frames)
      check_io!(failed: written < frames)
      written
    end

    # Writes +samples+ as floats and returns the file, for chaining.
    def <<(samples)
      write(samples)
      self
    end

    # Writes +data+, already encoded in the file's format (sf_write_raw).
    # Returns the number of bytes written.
    def write_raw(data)
      bytes = data.to_s.b
      buffer = FFI::MemoryPointer.new(:char, bytes.bytesize)
      buffer.put_bytes(0, bytes)
      written = Native.sf_write_raw(handle, buffer, bytes.bytesize)
      check_io!(failed: written < bytes.bytesize)
      written
    end

    # Forces written data to disk (sf_write_sync).
    def sync
      Native.sf_write_sync(handle)
      self
    end

    # Moves to frame +frames+, relative to +whence+ (:set, :cur or :end).
    # Returns the new position in frames.
    def seek(frames, whence = :set)
      position = Native.sf_seek(handle, frames, whence)
      check_io!(failed: position.negative?)
      position
    end

    # The current position in frames.
    def tell
      seek(0, :cur)
    end
    alias pos tell

    def rewind
      seek(0, :set)
      self
    end

    # Closes the file, writing any buffered data and the final header. Does
    # nothing when it is already closed.
    def close
      return if closed?

      result = Native.sf_close(handle)
      @closed = true
      @virtual_io&.raise_error!
      Error.check_error(result)
      nil
    end

    def closed?
      @closed == true
    end

    # libsndfile's description of the last error on this file.
    def error_message
      Native.sf_strerror(handle)
    end

    # The Native::Handle. Raises ClosedFileError once the file is closed.
    def handle
      raise ClosedFileError, "#{inspect} is closed" if closed?

      @handle
    end

    def inspect
      state = closed? ? "closed" : "#{format} #{channels}ch #{samplerate}Hz"
      "#<#{self.class.name} #{target_name} (#{mode}, #{state})>"
    end

    private

    def format_for(format, subtype, endian)
      return Format.coerce(format, subtype, endian) if format
      return unless mode == :write

      return Format.for_path(target) if path?(target)

      raise ArgumentError, "A format is needed to write to #{target.class}"
    end

    def native_info(format, samplerate, channels)
      check_write_options(format, samplerate, channels) if mode == :write
      Native::Info.new.tap do |info|
        info[:format] = format.to_i if format
        info[:samplerate] = samplerate.to_i if samplerate
        info[:channels] = channels.to_i if channels
      end
    end

    def check_write_options(format, samplerate, channels)
      raise ArgumentError, "Cannot tell the format of #{target_name}; pass format:" unless format

      missing = { samplerate: samplerate, channels: channels }.select { |_, value| value.nil? }.keys
      raise ArgumentError, "Writing needs #{missing.join(" and ")}" if missing.any?
      return if format.valid?(samplerate: samplerate, channels: channels)

      raise ArgumentError, "libsndfile cannot write #{format} with #{samplerate} Hz and #{channels} channel(s)"
    end

    def open_handle(target, info)
      if path?(target)
        Native.sf_open(target.to_s, mode, info)
      elsif target.respond_to?(:read) || target.respond_to?(:write)
        @virtual_io = VirtualIO.new(target)
        open_virtual(info)
      else
        raise ArgumentError, "Expected a path or an IO, got #{target.class}"
      end
    end

    def open_virtual(info)
      Native.sf_open_virtual(@virtual_io.struct, mode, info, nil)
    rescue SndFileError
      @virtual_io.raise_error!
      raise
    end

    def read_all(type)
      each_buffer(DEFAULT_BUFFER_FRAMES, type: type).reduce([], :concat)
    end

    def ffi_type_for(type)
      SAMPLE_TYPES.fetch(type) do
        raise ArgumentError, "Unknown sample type #{type.inspect}; expected one of #{SAMPLE_TYPES.keys.join(", ")}"
      end
    end

    def frame_count(samples)
      channel_count = channels
      unless (samples.size % channel_count).zero?
        raise ArgumentError, "#{samples.size} samples is not a whole number of #{channel_count}-channel frames"
      end

      samples.size / channel_count
    end

    # Raises an IO callback's exception, or libsndfile's error when +failed+
    # (a short write or failed seek) or when libsndfile recorded one.
    def check_io!(failed: false)
      @virtual_io&.raise_error!
      Error.check_sndfile(handle)
      raise SndFileError, error_message if failed
    end

    # Strings and Pathnames are paths; anything else is opened as an IO.
    def path?(target)
      target.is_a?(String) || (defined?(::Pathname) && target.is_a?(::Pathname))
    end

    def target_name
      path?(target) ? target.to_s.inspect : target.class.name
    end
  end
end
