# frozen_string_literal: true

require "stringio"

module SndFile
  RSpec.describe VirtualIO do
    let(:io) { StringIO.new((+"0123456789").b) }

    subject(:virtual_io) { described_class.new(io) }

    def call(name, *args)
      virtual_io.struct[name].call(*args, nil)
    end

    it "fills an SF_VIRTUAL_IO struct with callbacks" do
      expect(virtual_io.struct).to be_a(Native::VirtualIO)
      %i[get_filelen seek read write tell].each do |name|
        expect(virtual_io.struct[name]).to be_a(FFI::Function)
      end
    end

    it "reports the length" do
      expect(call(:get_filelen)).to be 10
    end

    it "uses stat for IOs without size" do
      file_like = instance_double(File, stat: instance_double(File::Stat, size: 42))
      expect(described_class.new(file_like).struct[:get_filelen].call(nil)).to be 42
    end

    it "reports an unknown length" do
      expect(described_class.new(Object.new).struct[:get_filelen].call(nil)).to be(-1)
    end

    it "seeks and tells" do
      expect(call(:seek, 4, IO::SEEK_SET)).to be 4
      expect(call(:seek, 2, IO::SEEK_CUR)).to be 6
      expect(call(:seek, -1, IO::SEEK_END)).to be 9
      expect(call(:tell)).to be 9
    end

    it "reads into the buffer" do
      buffer = FFI::MemoryPointer.new(:char, 4)
      expect(call(:read, buffer, 4)).to be 4
      expect(buffer.get_bytes(0, 4)).to eql "0123"
    end

    it "returns 0 at the end" do
      io.seek(0, IO::SEEK_END)
      expect(call(:read, FFI::MemoryPointer.new(:char, 4), 4)).to be 0
    end

    it "writes from the buffer" do
      buffer = FFI::MemoryPointer.new(:char, 3).put_bytes(0, "abc")
      expect(call(:write, buffer, 3)).to be 3
      expect(io.string).to eql "abc3456789"
    end

    describe "exceptions in the IO" do
      let(:io) { instance_double(StringIO, read: nil, pos: 0) }

      before { allow(io).to receive(:read).and_raise(IOError, "disk on fire") }

      it "are caught and reported as failures" do
        expect(call(:read, FFI::MemoryPointer.new(:char, 4), 4)).to be 0
        expect(virtual_io.error).to be_a(IOError)
      end

      it "are raised (once) by #raise_error!" do
        call(:read, FFI::MemoryPointer.new(:char, 4), 4)
        expect { virtual_io.raise_error! }.to raise_error(IOError, "disk on fire")
        expect { virtual_io.raise_error! }.not_to raise_error
      end

      it "keep the first error" do
        allow(io).to receive(:pos).and_raise(IOError, "second")
        call(:read, FFI::MemoryPointer.new(:char, 4), 4)
        expect(call(:tell)).to be(-1)
        expect(virtual_io.error.message).to eql "disk on fire"
      end
    end
  end
end
