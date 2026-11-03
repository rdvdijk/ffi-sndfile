# frozen_string_literal: true

module SndFile
  RSpec.describe Commands do
    def open_wav(**options)
      SoundFile.new(tmp_path("commands.wav"), :write, format: :wav, samplerate: 8000, channels: 1, **options)
    end

    let(:file) { open_wav }

    after { file.close }

    describe "#command" do
      it "runs an sf_command by symbol or constant" do
        info = Native::Info.new
        expect(file.command(:get_current_sf_info, info)).to be 0
        expect(info[:samplerate]).to be 8000
        expect(file.command(SFC_GET_CURRENT_SF_INFO, info, info.size)).to be 0
      end

      it "passes the file's handle" do
        expect(Native).to receive(:sf_command).with(file.handle, :update_header_now, nil, 0).and_return(0)
        file.command(:update_header_now)
      end
    end

    it "returns the log" do
      expect(file.log_info).to be_a(String)
    end

    describe "encoder settings" do
      let(:file) do
        SoundFile.new(tmp_path("commands.ogg"), :write, samplerate: 44_100, channels: 1)
      end

      it "sets the VBR quality" do
        expect { file.vbr_quality = 0.9 }.not_to raise_error
      end

      it "sets the compression level" do
        expect { file.compression_level = 0.2 }.not_to raise_error
      end

      it "raises when the format doesn't support a setting" do
        expect { file.bitrate_mode = :constant }
          .to raise_error(SndFileError, "Cannot set bitrate mode :constant for ogg/vorbis files")
      end

      it "rejects values that aren't numbers" do
        expect { file.vbr_quality = "high" }.to raise_error(ArgumentError)
      end
    end

    describe "#bitrate_mode" do
      it "returns the mode as a symbol" do
        allow(Native).to receive(:sf_command).and_return(SF_BITRATE_MODE_VARIABLE)
        expect(file.bitrate_mode).to be :variable
      end

      it "returns nil when the format has none" do
        allow(Native).to receive(:sf_command).and_return(-1)
        expect(file.bitrate_mode).to be_nil
      end

      it "sets the mode" do
        expect(Native).to receive(:sf_command)
          .with(file.handle, SFC_SET_BITRATE_MODE, kind_of(FFI::MemoryPointer), 4) do |_, _, pointer, _|
            expect(pointer.read_int).to be SF_BITRATE_MODE_AVERAGE
            SF_TRUE
          end
        file.bitrate_mode = :average
      end
    end

    describe "float normalization" do
      it "is on by default and can be turned off" do
        expect(file.normalize_float?).to be true
        file.normalize_float = false
        expect(file.normalize_float?).to be false
      end
    end

    describe "#update_header_now" do
      it "makes the file readable while it is being written" do
        file.write([0.5] * 10)
        expect(file.update_header_now).to be file
        expect(SoundFile.open(tmp_path("commands.wav"), &:frames)).to be 10
      end
    end

    describe "#truncate" do
      let(:file) { SoundFile.new(write_wav("t.wav", [0.1] * 10), :rdwr) }

      it "shortens the file" do
        expect(file.truncate(4)).to be file
        expect(file.frames).to be 4
      end

      it "raises when libsndfile refuses" do
        allow(Native).to receive(:sf_command).and_call_original
        allow(Native).to receive(:sf_command).with(anything, SFC_FILE_TRUNCATE, anything, 8).and_return(1)
        expect { file.truncate(4) }.to raise_error(SndFileError, /Cannot truncate/)
      end
    end

    describe "#signal_max" do
      let(:file) { SoundFile.new(write_wav("max.wav", [0.25, -0.5, 0.125]), :read) }

      it "returns the peak sample value" do
        expect(file.signal_max).to be_within(1).of(16_384)
        expect(file.signal_max(normalized: true)).to be_within(0.001).of(0.5)
      end
    end
  end
end
