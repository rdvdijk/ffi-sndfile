# frozen_string_literal: true

module SndFile
  RSpec.describe Formats do
    describe ".major_formats" do
      subject(:formats) { described_class.major_formats }

      it "lists the containers with name and extension" do
        wav = formats.find { |info| info.format.major == :wav }
        expect(wav.name).to include("WAV")
        expect(wav.extension).to eql "wav"
        expect(wav.format.subtype).to be 0
      end

      it "includes Ogg" do
        expect(formats.map { |info| info.format.major }).to include(:ogg)
      end
    end

    describe ".subtypes" do
      it "lists the encodings" do
        vorbis = described_class.subtypes.find { |info| info.format.subtype == :vorbis }
        expect(vorbis.name).to eql "Vorbis"
        expect(vorbis.format.major).to be 0
      end
    end

    describe ".simple_formats" do
      it "lists complete formats" do
        formats = described_class.simple_formats.map(&:format)
        expect(formats).to include(Format.new(:wav, :pcm_16), Format.new(:ogg, :vorbis))
      end
    end

    describe ".describe" do
      it "describes a major format or subtype by symbol" do
        expect(described_class.describe(:flac)).to have_attributes(name: include("FLAC"), extension: "flac")
        expect(described_class.describe(:pcm_16).name).to eql "Signed 16 bit PCM"
      end

      it "describes an integer" do
        expect(described_class.describe(SF_FORMAT_OGG).name).to include("OGG")
      end

      it "returns nil for formats libsndfile doesn't know" do
        expect(described_class.describe(0x7F_0000)).to be_nil
      end

      it "rejects unknown symbols" do
        expect { described_class.describe(:wma) }.to raise_error(ArgumentError, "Unknown format :wma")
      end
    end
  end
end
