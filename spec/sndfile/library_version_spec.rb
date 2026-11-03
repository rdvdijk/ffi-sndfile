# frozen_string_literal: true

module SndFile
  RSpec.describe LibraryVersion do
    subject(:version) { described_class.new }

    it "gets the version string" do
      expect(version.string).to eql Native.sf_version_string
    end

    it "parses major, minor and patch" do
      parsed = described_class.new("libsndfile-1.2.2")
      expect([parsed.major, parsed.minor, parsed.patch]).to eql [1, 2, 2]
    end

    it "ignores a suffix such as -exp" do
      expect(described_class.new("libsndfile-1.0.31-exp").number).to eql "1.0.31"
    end

    it "raises ArgumentError for strings without a version" do
      expect { described_class.new("libsndfile") }
        .to raise_error(ArgumentError, 'Cannot parse libsndfile version "libsndfile"')
    end

    it "formats as the library's string" do
      expect(version.to_s).to eql version.string
    end

    it "formats major.minor.patch as #number" do
      expect(version.number).to eql [version.major, version.minor, version.patch].join(".")
    end

    it "compares with version strings and other versions" do
      expect(version).to be >= described_class::MINIMUM
      expect(version).to be < "999.0.0"
      expect(described_class.new("libsndfile-1.0.28")).to be < described_class.new("libsndfile-1.2.0")
      expect(described_class.new("libsndfile-1.2.2")).to eq described_class.new("1.2.2")
    end

    it "inspects as the number" do
      expect(described_class.new("libsndfile-1.2.2").inspect).to eql "#<SndFile::LibraryVersion 1.2.2>"
    end

    describe ".ensure_supported!" do
      it "returns the version when libsndfile is new enough" do
        allow(Native).to receive(:sf_version_string).and_return("libsndfile-1.0.28")
        expect(described_class.ensure_supported!.number).to eql "1.0.28"
      end

      it "raises LoadError when libsndfile is too old" do
        allow(Native).to receive(:sf_version_string).and_return("libsndfile-1.0.27")
        expect { described_class.ensure_supported! }
          .to raise_error(LoadError, "ffi-sndfile needs libsndfile 1.0.28 or newer, but found 1.0.27")
      end
    end
  end
end
