# frozen_string_literal: true

module SndFile
  # The expected sizes and offsets come from compiling a C program against
  # libsndfile 1.2.2's sndfile.h with gcc on x86_64 Linux.
  RSpec.describe Native do
    describe "structs" do
      def offset(struct, field)
        struct.offset_of(field)
      end

      context "on a 64-bit platform", if: FFI::Platform::ADDRESS_SIZE == 64 do
        it "matches the C sizes" do
          expect(
            Native::Info => 32, Native::FormatInfo => 24, Native::DitherInfo => 24, Native::EmbedFileInfo => 16,
            Native::CuePoint => 280, Native::Cues => 28_004, Native::Instrument => 272, Native::LoopInfo => 44,
            Native::BroadcastInfo => 864, Native::CartTimer => 8, Native::CartInfo => 2308,
            Native::VirtualIO => 40, Native::ChunkInfo => 80
          ).to all(satisfy { |struct, size| struct.size == size })
        end

        it "matches the C field offsets" do
          expect(offset(Native::Info, :samplerate)).to be 8
          expect(offset(Native::Info, :seekable)).to be 24
          expect(offset(Native::CuePoint, :name)).to be 24
          expect(offset(Native::Instrument, :loop_count)).to be 12
          expect(offset(Native::Instrument, :loops)).to be 16
          expect(offset(Native::LoopInfo, :bpm)).to be 12
          expect(offset(Native::LoopInfo, :future)).to be 20
          expect(offset(Native::BroadcastInfo, :time_reference_low)).to be 340
          expect(offset(Native::BroadcastInfo, :version)).to be 348
          expect(offset(Native::BroadcastInfo, :umid)).to be 350
          expect(offset(Native::BroadcastInfo, :loudness_value)).to be 414
          expect(offset(Native::BroadcastInfo, :coding_history_size)).to be 604
          expect(offset(Native::BroadcastInfo, :coding_history)).to be 608
          expect(offset(Native::CartInfo, :level_reference)).to be 680
          expect(offset(Native::CartInfo, :post_timers)).to be 684
          expect(offset(Native::CartInfo, :url)).to be 1024
          expect(offset(Native::CartInfo, :tag_text_size)).to be 2048
          expect(offset(Native::CartInfo, :tag_text)).to be 2052
          expect(offset(Native::ChunkInfo, :id_size)).to be 64
          expect(offset(Native::ChunkInfo, :data)).to be 72
        end
      end

      describe Native::CharArrayFields do
        subject(:broadcast) { Native::BroadcastInfo.new }

        it "writes and reads strings in char array fields" do
          broadcast.set_string(:description, "A description")
          broadcast.set_string(:originator, "Me")
          expect(broadcast.string(:description)).to eql "A description"
          expect(broadcast.string(:originator)).to eql "Me"
        end

        it "returns the assigned value" do
          expect(broadcast.set_string(:originator, "Me")).to eql "Me"
        end

        it "allows a value that fills the field exactly" do
          broadcast.set_string(:origination_date, "2026-11-03")
          expect(broadcast.string(:origination_date)).to eql "2026-11-03"
        end

        it "clears what was there before" do
          broadcast.set_string(:originator, "A long originator")
          broadcast.set_string(:originator, "Short")
          expect(broadcast.string(:originator)).to eql "Short"
        end

        it "rejects values that don't fit" do
          expect { broadcast.set_string(:origination_date, "2026-11-03T12") }
            .to raise_error(ArgumentError, "origination_date is at most 10 bytes, got 13")
        end
      end

      it "round-trips a broadcast (bext) chunk through a WAV file" do
        path = tmp_path("bext.wav")
        bext = Native::BroadcastInfo.new
        bext.set_string(:description, "Recorded in Ruby")
        bext.set_string(:originator, "ffi-sndfile")
        bext[:time_reference_low] = 48_000

        SoundFile.open(path, :write, format: :wav, samplerate: 48_000, channels: 1) do |file|
          expect(file.command(:set_broadcast_info, bext)).to be SF_TRUE
          file.write([0.0])
        end

        read = Native::BroadcastInfo.new
        SoundFile.open(path) { |file| expect(file.command(:get_broadcast_info, read)).to be SF_TRUE }
        expect(read.string(:description)).to eql "Recorded in Ruby"
        expect(read.string(:originator)).to eql "ffi-sndfile"
        expect(read[:time_reference_low]).to be 48_000
      end

      it "round-trips instrument data through a WAV file" do
        path = tmp_path("inst.wav")
        instrument = Native::Instrument.new
        instrument[:basenote] = 60
        instrument[:loop_count] = 1
        instrument[:loops][0][:mode] = SF_LOOP_FORWARD
        instrument[:loops][0][:start] = 10
        instrument[:loops][0][:end] = 90

        SoundFile.open(path, :write, format: :wav, samplerate: 8000, channels: 1) do |file|
          expect(file.command(:set_instrument, instrument)).to be SF_TRUE
          file.write([0.0] * 100)
        end

        read = Native::Instrument.new
        SoundFile.open(path) { |file| expect(file.command(:get_instrument, read)).to be SF_TRUE }
        expect(read[:basenote]).to be 60
        expect(read[:loops][0][:mode]).to be SF_LOOP_FORWARD
        expect(read[:loops][0][:end]).to be 90
      end
    end
  end
end
