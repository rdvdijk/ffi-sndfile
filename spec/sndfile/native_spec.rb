# frozen_string_literal: true

module SndFile
  RSpec.describe Native do
    let(:path) { tmp_path("native.wav") }

    def write_info(format: SF_FORMAT_WAV | SF_FORMAT_PCM_16, samplerate: 8000, channels: 1)
      Native::Info.new.tap do |info|
        info[:format] = format
        info[:samplerate] = samplerate
        info[:channels] = channels
      end
    end

    # Writes +values+ as 16 bit samples to a new WAV file and returns its
    # still open handle.
    def write_shorts(values)
      sndfile = described_class.sf_open(path, :write, write_info)
      buffer = FFI::MemoryPointer.new(:short, values.size).put_array_of_short(0, values)
      expect(described_class.sf_write_short(sndfile, buffer, values.size)).to be values.size
      sndfile
    end

    it "is the FFI library for libsndfile" do
      expect(described_class).to be_a(FFI::Library)
      expect(described_class).to respond_to(:sf_open, :sf_command, :sf_get_chunk_data)
    end

    it "attaches every function in sndfile.h" do
      functions = %i[
        sf_open sf_open_fd sf_open_virtual sf_error sf_strerror sf_error_number sf_perror sf_error_str
        sf_command sf_format_check sf_seek sf_set_string sf_get_string sf_version_string sf_current_byterate
        sf_read_raw sf_write_raw sf_readf_short sf_writef_short sf_readf_int sf_writef_int sf_readf_float
        sf_writef_float sf_readf_double sf_writef_double sf_read_short sf_write_short sf_read_int sf_write_int
        sf_read_float sf_write_float sf_read_double sf_write_double sf_close sf_write_sync sf_set_chunk
        sf_get_chunk_iterator sf_next_chunk_iterator sf_get_chunk_size sf_get_chunk_data
      ]
      expect(functions.reject { |name| described_class.respond_to?(name) }).to be_empty
    end

    it "returns the version string" do
      expect(described_class.sf_version_string).to match(/\Alibsndfile-\d+\.\d+\.\d+/)
    end

    describe "sf_format_check" do
      it "accepts valid combinations" do
        expect(described_class.sf_format_check(write_info)).to be SF_TRUE
        expect(described_class.sf_format_check(write_info(format: SF_FORMAT_OGG | SF_FORMAT_VORBIS))).to be SF_TRUE
      end

      it "rejects invalid combinations" do
        expect(described_class.sf_format_check(write_info(format: SF_FORMAT_WAV | SF_FORMAT_VORBIS))).to be SF_FALSE
        expect(described_class.sf_format_check(write_info(channels: 0))).to be SF_FALSE
      end
    end

    describe "opening, writing and reading" do
      it "writes and reads samples" do
        described_class.sf_close(write_shorts([100, -200, 300]))

        info = Native::Info.new
        sndfile = described_class.sf_open(path, :read, info)
        expect(info[:frames]).to be 3
        expect(info[:samplerate]).to be 8000
        expect(info[:format]).to be(SF_FORMAT_WAV | SF_FORMAT_PCM_16)

        buffer = FFI::MemoryPointer.new(:short, 3)
        expect(described_class.sf_readf_short(sndfile, buffer, 3)).to be 3
        expect(buffer.get_array_of_short(0, 3)).to eql [100, -200, 300]
        expect(described_class.sf_close(sndfile)).to be 0
      end

      it "returns a Handle that closes itself" do
        sndfile = write_shorts([1])
        expect(sndfile).to be_a(Native::Handle)
        expect(sndfile).to be_autorelease
        sndfile.free
      end

      it "accepts the integer constants for the mode" do
        described_class.sf_close(write_shorts([1]))
        sndfile = described_class.sf_open(path, SFM_READ, Native::Info.new)
        expect(described_class.sf_error(sndfile)).to be SF_ERR_NO_ERROR
        described_class.sf_close(sndfile)
      end

      it "rejects unknown symbols for enum parameters" do
        expect do
          described_class.sf_open(path, :sometimes, Native::Info.new)
        end.to raise_error(ArgumentError, /invalid enum value/)
      end

      it "raises instead of returning NULL when a file can't be opened" do
        expect do
          described_class.sf_open(tmp_path("missing.wav"), :read, Native::Info.new)
        end.to raise_error(SystemError, /No such file/)
      end

      it "opens file descriptors with sf_open_fd" do
        described_class.sf_close(write_shorts([7, 8]))
        File.open(path, "rb") do |io|
          info = Native::Info.new
          sndfile = described_class.sf_open_fd(io.fileno, :read, info, SF_FALSE)
          expect(info[:frames]).to be 2
          described_class.sf_close(sndfile)
        end
      end
    end

    describe "seeking" do
      it "moves to a frame and reports the position" do
        sndfile = write_shorts([1, 2, 3, 4])
        expect(described_class.sf_seek(sndfile, 1, :set)).to be 1
        expect(described_class.sf_seek(sndfile, 0, :cur)).to be 1
        expect(described_class.sf_seek(sndfile, 0, SF_SEEK_END)).to be 4
        described_class.sf_close(sndfile)
      end
    end

    describe "strings" do
      it "sets and gets strings" do
        sndfile = described_class.sf_open(path, :write, write_info)
        expect(described_class.sf_set_string(sndfile, :title, "Like a Hurricane")).to be 0
        expect(described_class.sf_set_string(sndfile, SF_STR_ARTIST, "Neil Young")).to be 0
        expect(described_class.sf_get_string(sndfile, :title)).to eql "Like a Hurricane"
        expect(described_class.sf_get_string(sndfile, :artist)).to eql "Neil Young"
        expect(described_class.sf_get_string(sndfile, :genre)).to be_nil
        described_class.sf_close(sndfile)
      end
    end

    describe "sf_command" do
      it "works without a file for library-wide commands" do
        count = FFI::MemoryPointer.new(:int)
        expect(described_class.sf_command(nil, :get_format_major_count, count, count.size)).to be 0
        expect(count.read_int).to be > 10
      end

      it "returns the version string with SFC_GET_LIB_VERSION" do
        buffer = FFI::MemoryPointer.new(:char, 128)
        described_class.sf_command(nil, :get_lib_version, buffer, buffer.size)
        expect(buffer.read_string).to eql described_class.sf_version_string
      end

      it "describes a format" do
        info = Native::FormatInfo.new
        info[:format] = SF_FORMAT_FLAC
        expect(described_class.sf_command(nil, SFC_GET_FORMAT_INFO, info, info.size)).to be 0
        expect(info[:name]).to include("FLAC")
        expect(info[:extension]).to eql "flac"
      end

      it "gets the current SF_INFO of a file being written" do
        sndfile = write_shorts([1, 2, 3])
        info = Native::Info.new
        described_class.sf_command(sndfile, :get_current_sf_info, info, info.size)
        expect(info[:frames]).to be 3
        described_class.sf_close(sndfile)
      end
    end

    describe "errors" do
      it "has no error on a healthy file" do
        sndfile = write_shorts([1])
        expect(described_class.sf_error(sndfile)).to be SF_ERR_NO_ERROR
        expect(described_class.sf_strerror(sndfile)).to match(/no error/i)
        described_class.sf_close(sndfile)
      end

      it "describes the public error numbers" do
        expect(described_class.sf_error_number(SF_ERR_UNRECOGNISED_FORMAT)).to match(/not recognised/i)
        expect(described_class.sf_error_number(SF_ERR_SYSTEM)).to match(/system/i)
      end

      it "copies the error text with the deprecated sf_error_str" do
        sndfile = write_shorts([1])
        buffer = FFI::MemoryPointer.new(:char, 256)
        expect(described_class.sf_error_str(sndfile, buffer, buffer.size)).to be 0
        expect(buffer.read_string).to match(/no error/i)
        described_class.sf_close(sndfile)
      end
    end

    describe "raw data, byterate and sync" do
      it "writes and reads raw bytes" do
        sndfile = described_class.sf_open(path, :write, write_info)
        data = [1, 2, 3].pack("s<*")
        buffer = FFI::MemoryPointer.new(:char, data.bytesize).put_bytes(0, data)
        expect(described_class.sf_write_raw(sndfile, buffer, data.bytesize)).to be data.bytesize
        described_class.sf_write_sync(sndfile)
        expect(described_class.sf_current_byterate(sndfile)).to be 16_000
        described_class.sf_close(sndfile)

        sndfile = described_class.sf_open(path, :read, Native::Info.new)
        read = FFI::MemoryPointer.new(:char, 16)
        expect(described_class.sf_read_raw(sndfile, read, 16)).to be 6
        expect(read.get_bytes(0, 6)).to eql data
        described_class.sf_close(sndfile)
      end
    end

    describe "chunks" do
      it "adds a custom chunk and reads it back with the chunk iterator" do
        sndfile = described_class.sf_open(path, :write, write_info)
        data = FFI::MemoryPointer.new(:char, 8).put_bytes(0, "chunky!!")
        chunk = Native::ChunkInfo.new
        chunk.set_string(:id, "TEST")
        chunk[:id_size] = 4
        chunk[:datalen] = 8
        chunk[:data] = data
        expect(described_class.sf_set_chunk(sndfile, chunk)).to be 0
        described_class.sf_close(sndfile)

        sndfile = described_class.sf_open(path, :read, Native::Info.new)
        iterator = described_class.sf_get_chunk_iterator(sndfile, chunk)
        expect(iterator).not_to be_null

        found = Native::ChunkInfo.new
        expect(described_class.sf_get_chunk_size(iterator, found)).to be 0
        expect(found[:datalen]).to be 8
        found[:data] = FFI::MemoryPointer.new(:char, found[:datalen])
        expect(described_class.sf_get_chunk_data(iterator, found)).to be 0
        expect(found[:data].get_bytes(0, 8)).to eql "chunky!!"
        expect(described_class.sf_next_chunk_iterator(iterator)).to be_null
        described_class.sf_close(sndfile)
      end
    end
  end
end
