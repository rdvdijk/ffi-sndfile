# frozen_string_literal: true

require "open3"
require "stringio"

# Writes real Ogg/Vorbis files with libsndfile and checks them twice: with
# OggVorbisReader (a parser independent of libsndfile) and by reading them
# back through this gem.
RSpec.describe "Ogg/Vorbis files with Vorbis comments" do
  let(:samplerate) { 44_100 }
  let(:channels) { 2 }
  let(:frames) { samplerate } # one second
  let(:samples) { sine(frames: frames, samplerate: samplerate, channels: channels) }
  let(:path) { tmp_path("song.ogg") }

  let(:strings) do
    {
      title: "Heart of Gold",
      artist: "Neil Young",
      album: "Harvest",
      date: "1972",
      genre: "Rock",
      tracknumber: "4",
      comment: "Café ☕ – ünïcödé ♫",
      copyright: "© 1972 Reprise Records",
      license: "All rights reserved"
    }
  end

  # The Vorbis comment field libsndfile writes for each string.
  let(:expected_comments) do
    {
      "TITLE" => "Heart of Gold",
      "ARTIST" => "Neil Young",
      "ALBUM" => "Harvest",
      "DATE" => "1972",
      "GENRE" => "Rock",
      "TRACKNUMBER" => "4",
      "COMMENT" => "Café ☕ – ünïcödé ♫",
      "COPYRIGHT" => "© 1972 Reprise Records",
      "LICENSE" => "All rights reserved"
    }
  end

  def write_ogg(target = path, **options)
    SndFile::SoundFile.open(target, :write, format: :ogg, subtype: :vorbis, samplerate: samplerate,
                                            channels: channels, strings: strings, **options) do |file|
      file.vbr_quality = 0.5
      samples.each_slice(4096 * channels) { |buffer| file.write(buffer) }
      file.frames
    end
  end

  before do
    format = SndFile::Format.new(:ogg, :vorbis)
    skip "this libsndfile was built without Ogg/Vorbis" unless format.valid?(samplerate: samplerate, channels: channels)
  end

  describe "the written file, read independently of libsndfile" do
    subject(:ogg) { OggVorbisReader.read(path) }

    before { write_ogg }

    it "is a valid Ogg stream: every page has the capture pattern and a correct CRC" do
      expect(ogg.pages).not_to be_empty
      expect(ogg.pages.first).to be_first
      expect(ogg.pages.last).to be_last
      expect(ogg.pages.map(&:serial).uniq.size).to be 1
      expect(ogg.pages.map(&:sequence)).to eql (0...ogg.pages.size).to_a
    end

    it "starts with a Vorbis identification header for the sample rate and channels" do
      expect(ogg.identification).to include(channels: 2, samplerate: 44_100)
    end

    it "contains the strings as Vorbis comments" do
      comments = ogg.comment_hash.except("ENCODER")
      expect(comments.transform_values(&:first)).to eql expected_comments
      expect(comments.values).to all(have_attributes(size: 1))
    end

    it "stores the comments as UTF-8" do
      comment = ogg.comment_hash.fetch("COMMENT").first
      expect(comment.encoding).to be Encoding::UTF_8
      expect(comment).to be_valid_encoding
      expect(comment.bytesize).to be > comment.length
    end

    it "names libVorbis as the vendor" do
      expect(ogg.vendor).to include("libVorbis")
    end

    it "ends at the number of frames written" do
      expect(ogg.total_frames).to be frames
    end
  end

  describe "the written file, read back with SndFile" do
    before { write_ogg }

    it "reports the format, sample rate, channels and length" do
      SndFile.open(path) do |file|
        expect(file.format).to eq SndFile::Format.new(:ogg, :vorbis)
        expect(file.samplerate).to be samplerate
        expect(file.channels).to be channels
        expect(file.frames).to be frames
        expect(file.duration).to be_within(0.001).of(1.0)
      end
    end

    it "reads the Vorbis comments back as strings" do
      SndFile.open(path) do |file|
        expect(file.strings.to_h).to include(strings)
        expect(file.strings.comment.encoding).to be Encoding::UTF_8
      end
    end

    it "decodes audio that matches what was written (within lossy encoding error)" do
      decoded = SndFile.open(path, &:read)

      expect(decoded.size).to be samples.size
      expect(rms(decoded)).to be_within(0.02).of(rms(samples))
      error = decoded.zip(samples).map { |actual, expected| actual - expected }
      expect(rms(error)).to be < 0.05
    end
  end

  it "returns the frame count from the open block" do
    expect(write_ogg).to be frames
  end

  it "writes Ogg/Vorbis into memory through a StringIO" do
    io = StringIO.new(+"".b)
    write_ogg(io)

    ogg = OggVorbisReader.new(io.string)
    expect(ogg.comment_hash.fetch("TITLE")).to eql ["Heart of Gold"]
    expect(ogg.total_frames).to be frames

    io.rewind
    SndFile.open(io) { |file| expect(file.strings.artist).to eql "Neil Young" }
  end

  it "picks Ogg/Vorbis from the .ogg extension" do
    SndFile.open(path, :write, samplerate: samplerate, channels: channels, strings: { title: "By extension" }) do |file|
      file.write(samples.first(1000))
    end

    expect(OggVorbisReader.read(path).comment_hash.fetch("TITLE")).to eql ["By extension"]
  end

  it "refuses strings once audio has been written" do
    SndFile.open(path, :write, samplerate: samplerate, channels: channels) do |file|
      file.write(samples.first(1000))
      expect { file.strings.title = "Too late" }.to raise_error(SndFile::SndFileError)
    end
  end

  it "can be read by vorbiscomment from vorbis-tools" do
    skip "vorbiscomment is not installed" unless system("vorbiscomment --version", out: File::NULL, err: File::NULL)
    write_ogg

    output, status = Open3.capture2("vorbiscomment", "--list", "--raw", path)
    expect(status).to be_success
    # Field names are case-insensitive; libsndfile writes e.g. "Genre".
    listed = output.force_encoding(Encoding::UTF_8).lines(chomp: true).to_h do |line|
      field, value = line.split("=", 2)
      [field.upcase, value]
    end
    expect(listed).to include(expected_comments)
  end
end
