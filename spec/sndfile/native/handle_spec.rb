# frozen_string_literal: true

module SndFile
  RSpec.describe Native::Handle do
    let(:path) { write_wav("handle.wav", [0.0]) }

    it "is returned by Native.sf_open" do
      handle = Native.sf_open(path, :read, Native::Info.new)
      expect(handle).to be_a(described_class)
      Native.sf_close(handle)
    end

    it "raises libsndfile's error when sf_open returns NULL" do
      allow(Native).to receive(:sf_error).with(nil).and_return(SF_ERR_UNRECOGNISED_FORMAT)
      allow(Native).to receive(:sf_strerror).with(nil).and_return("Format not recognised.")

      expect { described_class.from_native(FFI::Pointer::NULL, nil) }
        .to raise_error(UnrecognisedFormatError, "Format not recognised.")
    end

    it "closes the SNDFILE pointer when released" do
      pointer = FFI::Pointer.new(0x1234)
      expect(Native).to receive(:sf_close_pointer).with(pointer)
      described_class.release(pointer)
    end

    it "is not released again after Native.sf_close" do
      handle = Native.sf_open(path, :read, Native::Info.new)
      expect(Native.sf_close(handle)).to be 0
      expect(handle).not_to be_autorelease
    end
  end
end
