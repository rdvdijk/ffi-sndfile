# frozen_string_literal: true

RSpec.describe SndFile do
  it "keeps the libsndfile functions out of the public module" do
    expect(described_class).not_to respond_to(:sf_open)
    expect(described_class.singleton_class).not_to include(FFI::Library)
  end

  it "does not hide Ruby's ::FFI or ::File inside module SndFile" do
    expect(described_class.const_defined?(:FFI, false)).to be false
    expect(described_class.const_defined?(:File, false)).to be false
  end

  it "can be loaded under the gem's name with require \"ffi-sndfile\"" do
    require "ffi-sndfile"
    expect($LOADED_FEATURES).to include(File.expand_path("../lib/ffi-sndfile.rb", __dir__))
  end

  it "has a version number" do
    expect(SndFile::VERSION).to match(/\A\d+\.\d+\.\d+\z/)
  end

  describe ".version" do
    it "returns the loaded library's version" do
      expect(described_class.version).to be_a(SndFile::LibraryVersion)
      expect(described_class.version.to_s).to eql SndFile::Native.sf_version_string
    end
  end

  describe ".open" do
    it "opens a SoundFile and passes the block along" do
      path = write_wav("a.wav", [0.25])
      expect(described_class.open(path, &:frames)).to be 1
    end

    it "passes the mode and options along" do
      path = tmp_path("b.wav")
      described_class.open(path, :write, samplerate: 8000, channels: 1) { |file| file.write([0.0, 0.0]) }
      expect(described_class.open(path, &:frames)).to be 2
    end
  end

  describe "format listings" do
    it "lists the major formats, subtypes and simple formats" do
      expect(described_class.major_formats.map { |info| info.format.major }).to include(:wav, :flac, :ogg)
      expect(described_class.subtypes.map { |info| info.format.subtype }).to include(:pcm_16, :vorbis)
      expect(described_class.simple_formats).to all(be_a(SndFile::FormatDescription))
    end
  end
end
