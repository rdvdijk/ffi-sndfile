# frozen_string_literal: true

module SndFile
  # FFI enum types for the libsndfile constants in SndFile (see
  # constants.rb). Functions that take these values are attached with the
  # enum type, so they accept symbols such as :read or :title as well as the
  # integer constants. Each symbol is the constant's name without its prefix,
  # in lower case: SFC_SET_VBR_ENCODING_QUALITY is :set_vbr_encoding_quality.
  module Native
    # Defines an enum named +name+ from the constants +prefix+<suffix>.
    def self.constant_enum(name, prefix, suffixes)
      values = suffixes.flat_map do |suffix|
        [suffix.downcase.to_sym, SndFile.const_get(:"#{prefix}#{suffix}")]
      end
      enum name, values
    end
    private_class_method :constant_enum

    constant_enum :sf_major_format, "SF_FORMAT_", %w[
      WAV AIFF AU RAW PAF SVX NIST VOC IRCAM W64 MAT4 MAT5 PVF XI HTK SDS AVR
      WAVEX SD2 FLAC CAF WVE OGG MPC2K RF64 MPEG
    ]

    constant_enum :sf_subtype, "SF_FORMAT_", %w[
      PCM_S8 PCM_16 PCM_24 PCM_32 PCM_U8 FLOAT DOUBLE ULAW ALAW IMA_ADPCM
      MS_ADPCM GSM610 VOX_ADPCM NMS_ADPCM_16 NMS_ADPCM_24 NMS_ADPCM_32 G721_32
      G723_24 G723_40 DWVW_12 DWVW_16 DWVW_24 DWVW_N DPCM_8 DPCM_16 VORBIS OPUS
      ALAC_16 ALAC_20 ALAC_24 ALAC_32 MPEG_LAYER_I MPEG_LAYER_II MPEG_LAYER_III
    ]

    constant_enum :sf_endian, "SF_ENDIAN_", %w[FILE LITTLE BIG CPU]

    commands = SndFile.constants.grep(/\ASFC_/).map { |name| name.to_s.delete_prefix("SFC_") }
    constant_enum :sf_command, "SFC_", commands

    constant_enum :sf_str, "SF_STR_", %w[
      TITLE COPYRIGHT SOFTWARE ARTIST COMMENT DATE ALBUM LICENSE TRACKNUMBER GENRE
    ]

    constant_enum :sf_mode, "SFM_", %w[READ WRITE RDWR]

    constant_enum :sf_ambisonic, "SF_AMBISONIC_", %w[NONE B_FORMAT]

    constant_enum :sf_error, "SF_ERR_", %w[
      NO_ERROR UNRECOGNISED_FORMAT SYSTEM MALFORMED_FILE UNSUPPORTED_ENCODING
    ]

    constant_enum :sf_channel_map, "SF_CHANNEL_MAP_", %w[
      INVALID MONO LEFT RIGHT CENTER FRONT_LEFT FRONT_RIGHT FRONT_CENTER
      REAR_CENTER REAR_LEFT REAR_RIGHT LFE FRONT_LEFT_OF_CENTER
      FRONT_RIGHT_OF_CENTER SIDE_LEFT SIDE_RIGHT TOP_CENTER TOP_FRONT_LEFT
      TOP_FRONT_RIGHT TOP_FRONT_CENTER TOP_REAR_LEFT TOP_REAR_RIGHT
      TOP_REAR_CENTER AMBISONIC_B_W AMBISONIC_B_X AMBISONIC_B_Y AMBISONIC_B_Z
    ]

    constant_enum :sf_bitrate_mode, "SF_BITRATE_MODE_", %w[CONSTANT AVERAGE VARIABLE]

    constant_enum :sf_dither, "SFD_", %w[NO_DITHER WHITE TRIANGULAR_PDF]

    constant_enum :sf_loop_mode, "SF_LOOP_", %w[NONE FORWARD BACKWARD ALTERNATING]

    constant_enum :sf_seek_whence, "SF_SEEK_", %w[SET CUR END]
  end
end
