# frozen_string_literal: true

module SndFile
  RSpec.describe Format do
    describe ".new" do
      it "combines a major format and a subtype" do
        expect(described_class.new(:ogg, :vorbis).to_i).to be(SF_FORMAT_OGG | SF_FORMAT_VORBIS)
      end

      it "accepts integer constants" do
        expect(described_class.new(SF_FORMAT_FLAC, SF_FORMAT_PCM_24).subtype).to be :pcm_24
      end

      it "accepts a complete format integer" do
        format = described_class.new(SF_FORMAT_WAV | SF_FORMAT_FLOAT | SF_ENDIAN_BIG)
        expect([format.major, format.subtype, format.endian]).to eql %i[wav float big]
      end

      it "accepts strings in any case" do
        expect(described_class.new("OGG", "Opus")).to eq described_class.new(:ogg, :opus)
      end

      it "adds the endianness" do
        expect(described_class.new(:aiff, :pcm_16,
                                   :little).to_i).to be(SF_FORMAT_AIFF | SF_FORMAT_PCM_16 | SF_ENDIAN_LITTLE)
      end

      it "defaults the subtype for common major formats" do
        expect(described_class.new(:wav).subtype).to be :pcm_16
        expect(described_class.new(:ogg).subtype).to be :vorbis
        expect(described_class.new(:mpeg).subtype).to be :mpeg_layer_iii
      end

      it "needs a subtype for other major formats" do
        expect { described_class.new(:voc) }.to raise_error(ArgumentError, "A subtype is needed for :voc files")
      end

      it "rejects unknown names" do
        expect { described_class.new(:wma) }.to raise_error(ArgumentError, "Unknown major format: :wma")
        expect { described_class.new(:ogg, :aac) }.to raise_error(ArgumentError, "Unknown subtype: :aac")
        expect { described_class.new(:wav, :pcm_16, :middle) }.to raise_error(ArgumentError, "Unknown endian: :middle")
      end

      it "is frozen" do
        expect(described_class.new(:wav)).to be_frozen
      end
    end

    describe ".coerce" do
      it "converts formats, integers, symbols and arrays" do
        ogg = described_class.new(:ogg, :vorbis)
        expect(described_class.coerce(ogg)).to be ogg
        expect(described_class.coerce(ogg.to_i)).to eq ogg
        expect(described_class.coerce(:ogg)).to eq ogg
        expect(described_class.coerce(:ogg, :vorbis)).to eq ogg
        expect(described_class.coerce(%i[ogg vorbis])).to eq ogg
        expect(described_class.coerce(:wav, :pcm_16, :big).endian).to be :big
      end

      it "rejects other values" do
        expect { described_class.coerce(1.5) }
          .to raise_error(ArgumentError, "Expected a Format, Integer, Symbol or Array, got Float")
      end
    end

    describe ".for_path" do
      it "picks the format from the extension" do
        expect(described_class.for_path("song.ogg")).to eq described_class.new(:ogg, :vorbis)
        expect(described_class.for_path("song.OPUS")).to eq described_class.new(:ogg, :opus)
        expect(described_class.for_path("/a/b/take.wav")).to eq described_class.new(:wav, :pcm_16)
        expect(described_class.for_path("x.mp3")).to eq described_class.new(:mpeg, :mpeg_layer_iii)
      end

      it "returns nil for unknown or missing extensions" do
        expect(described_class.for_path("notes.txt")).to be_nil
        expect(described_class.for_path("README")).to be_nil
      end
    end

    it "returns the integer for unknown parts" do
      format = described_class.new(0x7F_0000 | 0x00FF)
      expect(format.major).to be 0x7F_0000
      expect(format.subtype).to be 0xFF
    end

    describe "#valid?" do
      it "asks libsndfile whether it can write the combination" do
        expect(described_class.new(:wav, :pcm_16)).to be_valid(samplerate: 44_100, channels: 2)
        expect(described_class.new(:wav, :vorbis)).not_to be_valid(samplerate: 44_100, channels: 2)
      end
    end

    it "compares by value and works as a Hash key" do
      expect(described_class.new(:flac)).to eq described_class.new(SF_FORMAT_FLAC | SF_FORMAT_PCM_16)
      expect(described_class.new(:flac)).not_to eq described_class.new(:flac).to_i
      expect({ described_class.new(:flac) => 1 }).to have_key(described_class.new(:flac))
    end

    it "converts to an Integer implicitly, e.g. for SF_INFO fields" do
      info = Native::Info.new
      info[:format] = described_class.new(:ogg)
      expect(info[:format]).to be(SF_FORMAT_OGG | SF_FORMAT_VORBIS)
    end

    it "describes itself" do
      expect(described_class.new(:ogg, :vorbis).to_s).to eql "ogg/vorbis"
      expect(described_class.new(:wav, :pcm_16, :big).inspect).to eql "#<SndFile::Format wav/pcm_16/big>"
      expect(described_class.new(SF_FORMAT_FLAC).to_s).to eql "flac"
      expect(described_class.new(SF_FORMAT_VORBIS).to_s).to eql "vorbis"
    end
  end
end
