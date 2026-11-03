# frozen_string_literal: true

# Generates test signals and writes small test files.
module AudioHelpers
  # Interleaved samples of a sine wave, the same on every channel.
  def sine(frames:, samplerate: 44_100, channels: 2, frequency: 440.0, amplitude: 0.5)
    Array.new(frames) do |index|
      value = amplitude * Math.sin(2 * Math::PI * frequency * index / samplerate)
      [value] * channels
    end.flatten
  end

  # Writes +samples+ to a new 16 bit WAV file and returns its path.
  def write_wav(name, samples, channels: 1, samplerate: 8000, type: :float, **)
    path = tmp_path(name)
    SndFile::SoundFile.open(path, :write, format: :wav, samplerate: samplerate, channels: channels, **) do |file|
      file.write(samples, type: type)
    end
    path
  end

  # Root mean square of +samples+.
  def rms(samples)
    Math.sqrt(samples.sum { |sample| sample * sample } / samples.size)
  end
end
