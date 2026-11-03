# frozen_string_literal: true

require "pathname"
require "stringio"

module SndFile
  RSpec.describe SoundFile do
    let(:path) { tmp_path("sound.wav") }
    let(:stereo) { [0.5, -0.5, 0.25, -0.25, 0.0, 0.125] } # three stereo frames

    def write_stereo(target = path, **options)
      described_class.open(target, :write, format: :wav, samplerate: 8000, channels: 2, **options) do |file|
        file.write(stereo)
      end
    end

    describe ".open" do
      it "returns the open file without a block" do
        file = described_class.open(write_wav("a.wav", [0.0]))
        expect(file).not_to be_closed
        file.close
      end

      it "yields the file, closes it and returns the block's value" do
        write_stereo
        opened = nil
        result = described_class.open(path) do |file|
          opened = file
          :value
        end
        expect(result).to be :value
        expect(opened).to be_closed
      end

      it "closes the file when the block raises" do
        write_stereo
        opened = nil
        expect do
          described_class.open(path) do |file|
            opened = file
            raise "boom"
          end
        end.to raise_error(RuntimeError, "boom")
        expect(opened).to be_closed
      end
    end

    describe "#initialize" do
      it "opens for reading by default" do
        write_stereo
        file = described_class.new(path)
        expect(file.mode).to be :read
        expect(file.target).to eql path
        file.close
      end

      it "accepts the SFM_* constants and a Pathname" do
        write_stereo
        file = described_class.new(Pathname.new(path), SFM_RDWR)
        expect(file.mode).to be :rdwr
        file.close
      end

      it "rejects unknown modes" do
        expect { described_class.new(path, :append) }.to raise_error(ArgumentError, /invalid enum value/)
      end

      it "rejects targets that are neither paths nor IOs" do
        expect { described_class.new(42) }.to raise_error(ArgumentError, "Expected a path or an IO, got Integer")
      end

      it "raises libsndfile's error for files it can't open" do
        File.write(path, "this is not a WAV file")
        expect { described_class.new(path) }.to raise_error(UnrecognisedFormatError)
      end

      context "when writing" do
        it "takes the format as keywords, an Array, an Integer or a Format" do
          [
            { format: :wav, subtype: :pcm_24 },
            { format: %i[wav pcm_24] },
            { format: SF_FORMAT_WAV | SF_FORMAT_PCM_24 },
            { format: Format.new(:wav, :pcm_24) }
          ].each do |options|
            described_class.open(path, :write, samplerate: 8000, channels: 1, **options) do |file|
              expect(file.format).to eq Format.new(:wav, :pcm_24)
            end
          end
        end

        it "takes the endianness" do
          described_class.open(tmp_path("be.aiff"), :write, format: :aiff, endian: :little, samplerate: 8000,
                                                            channels: 1) do |file|
            expect(file.format.endian).to be :little
          end
        end

        it "picks the format from the extension" do
          described_class.open(tmp_path("x.flac"), :write, samplerate: 8000, channels: 1) do |file|
            expect(file.format).to eq Format.new(:flac, :pcm_16)
          end
        end

        it "needs a format when the extension doesn't give one" do
          expect { described_class.new(tmp_path("x.dat"), :write, samplerate: 8000, channels: 1) }
            .to raise_error(ArgumentError, /Cannot tell the format of ".*x\.dat"; pass format:/)
        end

        it "needs a format for IOs" do
          expect { described_class.new(StringIO.new, :write, samplerate: 8000, channels: 1) }
            .to raise_error(ArgumentError, "A format is needed to write to StringIO")
        end

        it "needs a sample rate and channel count" do
          expect { described_class.new(path, :write) }
            .to raise_error(ArgumentError, "Writing needs samplerate and channels")
          expect { described_class.new(path, :write, channels: 1) }
            .to raise_error(ArgumentError, "Writing needs samplerate")
        end

        it "rejects combinations libsndfile can't write" do
          expect { described_class.new(path, :write, format: %i[wav vorbis], samplerate: 8000, channels: 1) }
            .to raise_error(ArgumentError, "libsndfile cannot write wav/vorbis with 8000 Hz and 1 channel(s)")
        end

        it "sets strings before any audio is written" do
          described_class.open(path, :write, format: :wav, samplerate: 8000, channels: 1,
                                             strings: { title: "Ohio", artist: "Neil Young" }, &:close)
          expect(described_class.open(path) { |file| file.strings.to_h }).to eql(title: "Ohio", artist: "Neil Young")
        end
      end

      it "reads RAW files with the format given" do
        File.binwrite(path, [1000, -1000].pack("s<*"))
        described_class.open(path, :read, format: :raw, subtype: :pcm_16, endian: :little, samplerate: 8000,
                                          channels: 1) do |file|
          expect(file.read(2, type: :short)).to eql [1000, -1000]
        end
      end
    end

    describe "information" do
      before { write_stereo }

      it "reports the file's Info" do
        described_class.open(path) do |file|
          expect(file.info).to eql Info.new(frames: 3, samplerate: 8000, channels: 2, format: Format.new(:wav),
                                            sections: 1, seekable: true)
          expect([file.frames, file.samplerate, file.channels, file.sections]).to eql [3, 8000, 2, 1]
          expect(file.format).to eq Format.new(:wav, :pcm_16)
          expect(file).to be_seekable
          expect(file.duration).to eq 3.0 / 8000
        end
      end

      it "counts frames while writing" do
        described_class.open(tmp_path("w.wav"), :write, format: :wav, samplerate: 8000, channels: 1) do |file|
          expect(file.frames).to be 0
          file.write([0.0] * 5)
          expect(file.frames).to be 5
        end
      end

      it "reports the byte rate" do
        expect(described_class.open(path, &:byterate)).to be 32_000
      end

      it "returns nil for an unknown byte rate" do
        allow(Native).to receive(:sf_current_byterate).and_return(-1)
        expect(described_class.open(path, &:byterate)).to be_nil
      end

      it "has strings" do
        described_class.open(path) { |file| expect(file.strings).to be_a(Strings) }
      end

      it "inspects with the format" do
        described_class.open(path) do |file|
          expect(file.inspect).to eql %(#<SndFile::SoundFile "#{path}" (read, wav/pcm_16 2ch 8000Hz)>)
        end
      end
    end

    describe "#read" do
      before { write_stereo }

      it "reads interleaved float samples" do
        described_class.open(path) do |file|
          expect(file.read(2)).to eql [0.5, -0.5, 0.25, -0.25]
          expect(file.read(2)).to eql [0.0, 0.125]
          expect(file.read(2)).to eql []
        end
      end

      it "reads everything without a frame count" do
        expect(described_class.open(path, &:read)).to eql stereo
      end

      it "reads shorts, ints and doubles" do
        described_class.open(path) do |file|
          expect(file.read(1, type: :short)).to eql [16_384, -16_384]
          expect(file.read(1, type: :int)).to eql [8192 << 16, -8192 << 16]
          expect(file.read(1, type: :double)).to eql [0.0, 0.125]
        end
      end

      it "rejects unknown sample types" do
        described_class.open(path) do |file|
          expect { file.read(1, type: :long) }
            .to raise_error(ArgumentError, "Unknown sample type :long; expected one of short, int, float, double")
        end
      end

      it "raises libsndfile's error when reading fails" do
        described_class.open(path, :write, format: :wav, samplerate: 8000, channels: 2) do |file|
          expect { file.read(1) }.to raise_error(SndFileError, /read/i)
        end
      end
    end

    describe "#each_buffer" do
      before { write_stereo }

      it "yields buffers until the end of the file" do
        buffers = described_class.open(path) { |file| file.each_buffer(2).to_a }
        expect(buffers).to eql [[0.5, -0.5, 0.25, -0.25], [0.0, 0.125]]
      end

      it "returns the file" do
        described_class.open(path) do |file|
          expect(file.each_buffer(2, type: :short) { |samples| expect(samples).to all(be_an(Integer)) }).to be file
        end
      end
    end

    describe "#write" do
      it "returns the number of frames written" do
        described_class.open(path, :write, format: :wav, samplerate: 8000, channels: 2) do |file|
          expect(file.write(stereo)).to be 3
          expect(file.write([])).to be 0
        end
      end

      it "writes each sample type" do
        described_class.open(path, :write, format: :wav, subtype: :pcm_32, samplerate: 8000, channels: 1) do |file|
          file.write([1000], type: :short)
          file.write([1 << 20], type: :int)
          file.write([0.25], type: :double)
        end
        expect(described_class.open(path) { |file| file.read(nil, type: :int) }).to eql [1000 << 16, 1 << 20, 1 << 29]
      end

      it "needs whole frames" do
        described_class.open(path, :write, format: :wav, samplerate: 8000, channels: 2) do |file|
          expect { file.write([0.1, 0.2, 0.3]) }
            .to raise_error(ArgumentError, "3 samples is not a whole number of 2-channel frames")
        end
      end

      it "chains with <<" do
        described_class.open(path, :write, format: :wav, samplerate: 8000, channels: 1) do |file|
          expect(file << [0.1] << [0.2]).to be file
          expect(file.frames).to be 2
        end
      end

      it "raises when libsndfile writes less than asked" do
        described_class.open(path, :write, format: :wav, samplerate: 8000, channels: 1) do |file|
          allow(Native).to receive_messages(sf_writef_float: 0, sf_strerror: "Disk full.")
          expect { file.write([0.1]) }.to raise_error(SndFileError, "Disk full.")
        end
      end

      it "raises for files opened for reading" do
        write_stereo
        described_class.open(path) do |file|
          expect { file.write([0.0, 0.0]) }.to raise_error(SndFileError, /open for read/)
        end
      end
    end

    describe "raw data" do
      it "writes and reads encoded bytes" do
        data = [1, -2, 3].pack("s<*")
        described_class.open(path, :write, format: :wav, samplerate: 8000, channels: 1) do |file|
          expect(file.write_raw(data)).to be 6
        end
        described_class.open(path) do |file|
          expect(file.read_raw(100)).to eql data
          expect(file.read_raw(100)).to eql ""
        end
      end
    end

    describe "#sync" do
      it "returns the file" do
        described_class.open(path, :write, format: :wav, samplerate: 8000, channels: 1) do |file|
          expect(file.sync).to be file
        end
      end
    end

    describe "seeking" do
      before { write_stereo }

      it "moves to a frame" do
        described_class.open(path) do |file|
          expect(file.seek(2)).to be 2
          expect(file.read(1)).to eql [0.0, 0.125]
          expect(file.tell).to be 3
          expect(file.pos).to be 3
          expect(file.seek(-2, :cur)).to be 1
          expect(file.seek(-1, :end)).to be 2
          expect(file.rewind).to be file
          expect(file.tell).to be 0
        end
      end

      it "raises when seeking out of the file" do
        described_class.open(path) do |file|
          expect { file.seek(100) }.to raise_error(SndFileError)
        end
      end
    end

    describe "#close" do
      it "closes the file once" do
        file = described_class.new(write_wav("c.wav", [0.0]))
        expect(file.close).to be_nil
        expect(file).to be_closed
        expect { file.close }.not_to raise_error
        expect(file.instance_variable_get(:@handle)).not_to be_autorelease
      end

      it "raises ClosedFileError when the file is used afterwards" do
        file = described_class.new(write_wav("c.wav", [0.0]))
        file.close
        expect { file.read(1) }.to raise_error(ClosedFileError, /is closed/)
        expect { file.strings.title }.to raise_error(ClosedFileError)
        expect(file.inspect).to end_with("(read, closed)>")
      end

      it "raises libsndfile's error when closing fails" do
        file = described_class.new(write_wav("c.wav", [0.0]))
        allow(Native).to receive(:sf_close).and_wrap_original do |original, handle|
          original.call(handle)
          SF_ERR_SYSTEM
        end
        expect { file.close }.to raise_error(SystemError)
        expect(file).to be_closed
      end
    end

    it "describes the last error" do
      described_class.open(write_wav("e.wav", [0.0])) do |file|
        expect(file.error_message).to match(/no error/i)
      end
    end

    describe "IO objects" do
      it "writes to and reads from a StringIO" do
        io = StringIO.new(+"".b)
        write_stereo(io)
        expect(io.string).to start_with("RIFF")

        io.rewind
        described_class.open(io) do |file|
          expect(file.target).to be io
          expect(file.read).to eql stereo
          expect(file.inspect).to start_with("#<SndFile::SoundFile StringIO (read,")
        end
      end

      it "reads from a File" do
        write_stereo
        File.open(path, "rb") { |io| expect(described_class.open(io, &:frames)).to be 3 }
      end

      it "raises the IO's exception when opening fails" do
        io = StringIO.new(+"".b)
        allow(io).to receive(:read).and_raise(IOError, "broken pipe")
        expect { described_class.new(io) }.to raise_error(IOError, "broken pipe")
      end

      it "raises libsndfile's error when the data is not a sound file" do
        expect { described_class.new(StringIO.new(+"garbage" * 10)) }.to raise_error(SndFileError)
      end

      it "raises the IO's exception when writing fails" do
        io = StringIO.new(+"".b)
        described_class.open(io, :write, format: :wav, samplerate: 8000, channels: 1) do |file|
          allow(io).to receive(:write).and_raise(IOError, "disk full")
          expect { file.write([0.0] * 10_000) }.to raise_error(IOError, "disk full")
          allow(io).to receive(:write).and_call_original
        end
      end
    end

    it "lets other threads run while it reads and writes" do
      ticks = 0
      ticker = Thread.new { loop { ticks += 1 and Thread.pass } }
      described_class.open(path, :write, format: :flac, samplerate: 44_100, channels: 2) do |file|
        file.write(sine(frames: 44_100))
      end
      ticker.kill.join
      expect(ticks).to be > 0
    end
  end
end
