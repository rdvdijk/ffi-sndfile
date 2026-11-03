# frozen_string_literal: true

# Writes audio in lossless formats and checks that reading it back gives
# exactly the same samples.
RSpec.describe "Lossless round trips" do
  let(:samples) do
    sine(frames: 1000, samplerate: 8000, channels: 2, amplitude: 0.9).map { |sample| (sample * 32_767).round }
  end

  {
    "WAV" => ["take.wav", %i[wav pcm_16]],
    "WAVEX" => ["take.wav", %i[wavex pcm_16]],
    "AIFF" => ["take.aiff", %i[aiff pcm_16]],
    "FLAC" => ["take.flac", %i[flac pcm_16]],
    "CAF" => ["take.caf", %i[caf pcm_16]],
    "W64" => ["take.w64", %i[w64 pcm_16]],
    "RF64" => ["take.rf64", %i[rf64 pcm_16]],
    "AU" => ["take.au", %i[au pcm_16]]
  }.each do |name, (file_name, format)|
    it "keeps every 16 bit sample in #{name}" do
      path = tmp_path(file_name)
      SndFile.open(path, :write, format: format, samplerate: 8000, channels: 2) do |file|
        file.write(samples, type: :short)
      end

      SndFile.open(path) do |file|
        expect(file.format).to eq SndFile::Format.new(*format)
        expect(file.frames).to be 1000
        expect(file.read(nil, type: :short)).to eql samples
      end
    end
  end

  it "keeps 32 bit floats in WAV" do
    floats = [0.1, -0.7, 1.0, -1.0].map { |value| [value].pack("e").unpack1("e") }
    path = tmp_path("float.wav")
    SndFile.open(path, :write, format: :wav, subtype: :float, samplerate: 48_000, channels: 1) do |file|
      file.write(floats)
    end
    expect(SndFile.open(path, &:read)).to eql floats
  end

  it "keeps strings in FLAC (as Vorbis comments)" do
    path = tmp_path("tags.flac")
    strings = { title: "Cortez the Killer", artist: "Neil Young & Crazy Horse ✓", album: "Zuma", date: "1975" }
    SndFile.open(path, :write, samplerate: 44_100, channels: 1, strings: strings) { |file| file.write([0.0] * 10) }
    expect(SndFile.open(path) { |file| file.strings.to_h }).to include(strings)
  end

  it "appends to a file opened for reading and writing" do
    path = write_wav("append.wav", [100, 200], type: :short)
    SndFile.open(path, :rdwr) do |file|
      file.seek(0, :end)
      file.write([300], type: :short)
    end
    expect(SndFile.open(path) { |file| file.read(nil, type: :short) }).to eql [100, 200, 300]
  end
end
