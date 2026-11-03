# frozen_string_literal: true

module SndFile
  RSpec.describe Info do
    let(:struct) do
      Native::Info.new.tap do |info|
        info[:frames] = 88_200
        info[:samplerate] = 44_100
        info[:channels] = 2
        info[:format] = SF_FORMAT_OGG | SF_FORMAT_VORBIS
        info[:sections] = 1
        info[:seekable] = SF_TRUE
      end
    end

    subject(:info) { described_class.from_native(struct) }

    it "copies the SF_INFO fields" do
      expect(info).to have_attributes(frames: 88_200, samplerate: 44_100, channels: 2, sections: 1)
      expect(info.format).to eq Format.new(:ogg, :vorbis)
      expect(info).to be_seekable
    end

    it "computes the duration in seconds" do
      expect(info.duration).to eq 2.0
    end

    it "has no duration without a sample rate" do
      expect(info.with(samplerate: 0).duration).to be_nil
    end

    it "is not seekable when libsndfile says so" do
      struct[:seekable] = SF_FALSE
      expect(described_class.from_native(struct)).not_to be_seekable
    end
  end
end
