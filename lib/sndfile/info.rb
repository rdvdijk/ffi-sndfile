# frozen_string_literal: true

module SndFile
  # What libsndfile knows about an open sound file (its SF_INFO): the number
  # of frames, sample rate, channel count, Format, number of sections and
  # whether it is seekable.
  Info = Data.define(:frames, :samplerate, :channels, :format, :sections, :seekable) do
    # Builds an Info from a Native::Info struct.
    def self.from_native(struct)
      new(frames: struct[:frames],
          samplerate: struct[:samplerate],
          channels: struct[:channels],
          format: Format.new(struct[:format]),
          sections: struct[:sections],
          seekable: struct[:seekable] == SF_TRUE)
    end

    def seekable?
      seekable
    end

    # The length in seconds, or nil when the sample rate is unknown.
    def duration
      frames.fdiv(samplerate) if samplerate.positive?
    end
  end
end
