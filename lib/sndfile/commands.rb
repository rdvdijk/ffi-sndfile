# frozen_string_literal: true

module SndFile
  # Methods for SoundFile that wrap libsndfile's sf_command. #command gives
  # access to every SFC_* command; the other methods cover common ones.
  #
  # Encoder settings (#vbr_quality=, #compression_level=, #bitrate_mode=)
  # must be set before the first audio data is written.
  module Commands
    # Runs an sf_command and returns its integer result. +command+ is an
    # SFC_* constant or its symbol (e.g. :get_log_info); +data+ is a pointer
    # (or FFI::Struct) of +size+ bytes, as the command expects.
    def command(command, data = nil, size = data.respond_to?(:size) ? data.size : 0)
      Native.sf_command(handle, command, data, size)
    end

    # libsndfile's log of what it did while opening the file.
    def log_info
      buffer = FFI::MemoryPointer.new(:char, 4096)
      command(SFC_GET_LOG_INFO, buffer, buffer.size)
      buffer.read_string
    end

    # Sets the encoding quality for variable bit rate formats such as Ogg
    # Vorbis, Opus, FLAC and MP3: 0.0 (lowest) to 1.0 (highest).
    def vbr_quality=(quality)
      set_double(SFC_SET_VBR_ENCODING_QUALITY, quality, "VBR encoding quality")
    end

    # Sets the compression level for formats such as FLAC, Ogg and MP3:
    # 0.0 (least compression) to 1.0 (most compression).
    def compression_level=(level)
      set_double(SFC_SET_COMPRESSION_LEVEL, level, "compression level")
    end

    # The bitrate mode (:constant, :average or :variable), for MPEG files.
    # Returns nil when the format has none.
    def bitrate_mode
      mode = command(SFC_GET_BITRATE_MODE)
      Native.enum_type(:sf_bitrate_mode)[mode] unless mode.negative?
    end

    def bitrate_mode=(mode)
      value = FFI::MemoryPointer.new(:int)
      value.write_int(Native.enum_type(:sf_bitrate_mode).to_native(mode, nil))
      check_command(SFC_SET_BITRATE_MODE, value, value.size, "bitrate mode #{mode.inspect}")
    end

    # Whether floating point data is normalized to -1.0..1.0 when reading
    # and writing (libsndfile's default is true).
    def normalize_float?
      command(SFC_GET_NORM_FLOAT) == SF_TRUE
    end

    def normalize_float=(normalize)
      command(SFC_SET_NORM_FLOAT, nil, normalize ? SF_TRUE : SF_FALSE)
    end

    # Writes the file header now, so the file is valid while it is being
    # written.
    def update_header_now
      command(SFC_UPDATE_HEADER_NOW)
      self
    end

    # Truncates the file to +frames+ frames.
    def truncate(frames)
      value = FFI::MemoryPointer.new(:int64)
      value.write_int64(frames)
      return self if command(SFC_FILE_TRUNCATE, value).zero?

      raise SndFileError, "Cannot truncate #{inspect} to #{frames} frames"
    end

    # The largest absolute sample value in the file (SFC_CALC_SIGNAL_MAX),
    # or with normalized: true, as a fraction of the format's full scale.
    def signal_max(normalized: false)
      value = FFI::MemoryPointer.new(:double)
      command(normalized ? SFC_CALC_NORM_SIGNAL_MAX : SFC_CALC_SIGNAL_MAX, value)
      Error.check_sndfile(handle)
      value.read_double
    end

    private

    def set_double(command_id, number, description)
      value = FFI::MemoryPointer.new(:double)
      value.write_double(Float(number))
      check_command(command_id, value, value.size, "#{description} #{number}")
    end

    # Runs a SET command that returns SF_TRUE on success.
    def check_command(command_id, data, size, description)
      return if command(command_id, data, size) == SF_TRUE

      raise SndFileError, "Cannot set #{description} for #{format} files"
    end
  end
end
