# frozen_string_literal: true

module SndFile
  RSpec.describe Native do
    describe "enums" do
      def enum(name)
        described_class.enum_type(name)
      end

      it "maps the major formats" do
        expect(enum(:sf_major_format)[:ogg]).to be SF_FORMAT_OGG
        expect(enum(:sf_major_format)[SF_FORMAT_WAV]).to be :wav
        expect(enum(:sf_major_format).symbols.size).to be 26
      end

      it "maps the subtypes" do
        expect(enum(:sf_subtype)[:vorbis]).to be SF_FORMAT_VORBIS
        expect(enum(:sf_subtype)[:mpeg_layer_iii]).to be SF_FORMAT_MPEG_LAYER_III
        expect(enum(:sf_subtype).symbols.size).to be 34
      end

      it "has a symbol for every SFC_* command" do
        commands = SndFile.constants.grep(/\ASFC_/)
        expect(enum(:sf_command).symbols.size).to be commands.size
        expect(enum(:sf_command)[:set_vbr_encoding_quality]).to be SFC_SET_VBR_ENCODING_QUALITY
        expect(enum(:sf_command)[:get_ogg_stream_serialno]).to be SFC_GET_OGG_STREAM_SERIALNO
      end

      it "maps the string types" do
        expect(enum(:sf_str).symbols).to eql %i[
          title copyright software artist comment date album license tracknumber genre
        ]
        expect(enum(:sf_str)[:genre]).to be SF_STR_GENRE
      end

      it "maps the modes, seek origins and other small enums" do
        expect(enum(:sf_mode).to_h).to eql(read: SFM_READ, write: SFM_WRITE, rdwr: SFM_RDWR)
        expect(enum(:sf_seek_whence).to_h).to eql(set: 0, cur: 1, end: 2)
        expect(enum(:sf_endian)[:big]).to be SF_ENDIAN_BIG
        expect(enum(:sf_bitrate_mode)[:variable]).to be SF_BITRATE_MODE_VARIABLE
        expect(enum(:sf_loop_mode)[:alternating]).to be SF_LOOP_ALTERNATING
        expect(enum(:sf_dither)[:triangular_pdf]).to be SFD_TRIANGULAR_PDF
        expect(enum(:sf_ambisonic)[:b_format]).to be SF_AMBISONIC_B_FORMAT
        expect(enum(:sf_error)[:malformed_file]).to be SF_ERR_MALFORMED_FILE
      end

      it "maps the channel map positions" do
        expect(enum(:sf_channel_map)[:mono]).to be SF_CHANNEL_MAP_MONO
        expect(enum(:sf_channel_map)[:ambisonic_b_z]).to be SF_CHANNEL_MAP_AMBISONIC_B_Z
        expect(enum(:sf_channel_map).symbols.size).to be SF_CHANNEL_MAP_MAX
      end

      it "keeps its helper for defining enums private" do
        expect(described_class).not_to respond_to(:constant_enum)
      end
    end
  end
end
