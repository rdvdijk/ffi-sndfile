# frozen_string_literal: true

module SndFile
  RSpec.describe Strings do
    let(:path) { tmp_path("strings.wav") }
    let(:file) { SoundFile.new(path, :write, format: :wav, samplerate: 8000, channels: 1) }

    subject(:strings) { file.strings }

    after { file.close }

    it "has an accessor for every libsndfile string type" do
      expect(described_class::NAMES).to eql %i[
        title copyright software artist comment date album license tracknumber genre
      ]
      described_class::NAMES.each do |name|
        expect(strings).to respond_to(name, :"#{name}=")
      end
    end

    it "sets and gets strings by accessor and by name" do
      strings.title = "Old Man"
      strings[:artist] = "Neil Young"
      strings["Album"] = "Harvest"
      strings.track_number = 3
      expect(strings[:title]).to eql "Old Man"
      expect(strings.artist).to eql "Neil Young"
      expect(strings.album).to eql "Harvest"
      expect(strings.tracknumber).to eql "3"
      expect(strings.track_number).to eql "3"
    end

    it "returns nil for strings that aren't set" do
      expect(strings.genre).to be_nil
    end

    it "returns strings as UTF-8" do
      strings.comment = "Señor"
      expect(strings.comment).to eql "Señor"
      expect(strings.comment.encoding).to be Encoding::UTF_8
    end

    it "returns binary strings when they aren't valid UTF-8" do
      allow(Native).to receive(:sf_get_string).and_return((+"\xFF\xFE").force_encoding(Encoding::BINARY))
      expect(strings.title.encoding).to be Encoding::BINARY
    end

    it "converts strings to UTF-8 before writing them" do
      strings.comment = "Café".encode(Encoding::ISO_8859_1)
      expect(strings.comment).to eql "Café"
    end

    it "updates several strings at once" do
      expect(strings.update(title: "Cinnamon Girl", genre: "Rock")).to be strings
      expect(strings.to_h).to eql(title: "Cinnamon Girl", genre: "Rock")
    end

    it "is Enumerable over the strings that are set" do
      strings.update(artist: "Neil Young", title: "Ohio")
      expect(strings.to_a).to eql [[:title, "Ohio"], [:artist, "Neil Young"]]
      expect(strings.each).to be_an(Enumerator)
      expect(strings.each { |_name, _value| nil }).to be strings
    end

    it "rejects unknown string names" do
      expect { strings[:composer] = "Neil Young" }.to raise_error(ArgumentError, /Unknown string :composer/)
      expect { strings[:composer] }.to raise_error(ArgumentError, /expected one of title, copyright/)
    end

    it "raises libsndfile's error when the format has no strings" do
      raw = SoundFile.new(tmp_path("x.raw"), :write, format: :raw, samplerate: 8000, channels: 1)
      expect { raw.strings.title = "Nope" }.to raise_error(SndFileError, /does not support string/)
      raw.close
    end

    it "inspects as its strings" do
      strings.title = "Harvest Moon"
      expect(strings.inspect).to eql "#<SndFile::Strings #{{ title: "Harvest Moon" }.inspect}>"
    end
  end
end
