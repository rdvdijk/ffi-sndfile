# frozen_string_literal: true

# The constants from sndfile.h, in the order of that header, with its comments.
module SndFile
  # The following file types can be read and written. A file type would
  # consist of a major type (ie SF_FORMAT_WAV) bitwise ORed with a minor type
  # (ie SF_FORMAT_PCM). SF_FORMAT_TYPEMASK and SF_FORMAT_SUBMASK can be used
  # to separate the major and minor file types.

  # Major formats.
  SF_FORMAT_WAV               = 0x010000
  SF_FORMAT_AIFF              = 0x020000
  SF_FORMAT_AU                = 0x030000
  SF_FORMAT_RAW               = 0x040000
  SF_FORMAT_PAF               = 0x050000
  SF_FORMAT_SVX               = 0x060000
  SF_FORMAT_NIST              = 0x070000
  SF_FORMAT_VOC               = 0x080000
  SF_FORMAT_IRCAM             = 0x0A0000
  SF_FORMAT_W64               = 0x0B0000
  SF_FORMAT_MAT4              = 0x0C0000
  SF_FORMAT_MAT5              = 0x0D0000
  SF_FORMAT_PVF               = 0x0E0000
  SF_FORMAT_XI                = 0x0F0000
  SF_FORMAT_HTK               = 0x100000
  SF_FORMAT_SDS               = 0x110000
  SF_FORMAT_AVR               = 0x120000
  SF_FORMAT_WAVEX             = 0x130000
  SF_FORMAT_SD2               = 0x160000
  SF_FORMAT_FLAC              = 0x170000
  SF_FORMAT_CAF               = 0x180000
  SF_FORMAT_WVE               = 0x190000
  SF_FORMAT_OGG               = 0x200000
  SF_FORMAT_MPC2K             = 0x210000
  SF_FORMAT_RF64              = 0x220000
  SF_FORMAT_MPEG              = 0x230000

  # Subtypes from here on.
  SF_FORMAT_PCM_S8            = 0x0001
  SF_FORMAT_PCM_16            = 0x0002
  SF_FORMAT_PCM_24            = 0x0003
  SF_FORMAT_PCM_32            = 0x0004
  SF_FORMAT_PCM_U8            = 0x0005
  SF_FORMAT_FLOAT             = 0x0006
  SF_FORMAT_DOUBLE            = 0x0007
  SF_FORMAT_ULAW              = 0x0010
  SF_FORMAT_ALAW              = 0x0011
  SF_FORMAT_IMA_ADPCM         = 0x0012
  SF_FORMAT_MS_ADPCM          = 0x0013
  SF_FORMAT_GSM610            = 0x0020
  SF_FORMAT_VOX_ADPCM         = 0x0021
  SF_FORMAT_NMS_ADPCM_16      = 0x0022
  SF_FORMAT_NMS_ADPCM_24      = 0x0023
  SF_FORMAT_NMS_ADPCM_32      = 0x0024
  SF_FORMAT_G721_32           = 0x0030
  SF_FORMAT_G723_24           = 0x0031
  SF_FORMAT_G723_40           = 0x0032
  SF_FORMAT_DWVW_12           = 0x0040
  SF_FORMAT_DWVW_16           = 0x0041
  SF_FORMAT_DWVW_24           = 0x0042
  SF_FORMAT_DWVW_N            = 0x0043
  SF_FORMAT_DPCM_8            = 0x0050
  SF_FORMAT_DPCM_16           = 0x0051
  SF_FORMAT_VORBIS            = 0x0060
  SF_FORMAT_OPUS              = 0x0064
  SF_FORMAT_ALAC_16           = 0x0070
  SF_FORMAT_ALAC_20           = 0x0071
  SF_FORMAT_ALAC_24           = 0x0072
  SF_FORMAT_ALAC_32           = 0x0073
  SF_FORMAT_MPEG_LAYER_I      = 0x0080
  SF_FORMAT_MPEG_LAYER_II     = 0x0081
  SF_FORMAT_MPEG_LAYER_III    = 0x0082

  # Endian-ness options.
  SF_ENDIAN_FILE              = 0x00000000
  SF_ENDIAN_LITTLE            = 0x10000000
  SF_ENDIAN_BIG               = 0x20000000
  SF_ENDIAN_CPU               = 0x30000000

  SF_FORMAT_SUBMASK           = 0x0000FFFF
  SF_FORMAT_TYPEMASK          = 0x0FFF0000
  SF_FORMAT_ENDMASK           = 0x30000000

  # The following are the valid command numbers for the sf_command()
  # interface. The use of these commands is documented in the file
  # command.html in the doc directory of the source code distribution.
  SFC_GET_LIB_VERSION             = 0x1000
  SFC_GET_LOG_INFO                = 0x1001
  SFC_GET_CURRENT_SF_INFO         = 0x1002
  SFC_GET_NORM_DOUBLE             = 0x1010
  SFC_GET_NORM_FLOAT              = 0x1011
  SFC_SET_NORM_DOUBLE             = 0x1012
  SFC_SET_NORM_FLOAT              = 0x1013
  SFC_SET_SCALE_FLOAT_INT_READ    = 0x1014
  SFC_SET_SCALE_INT_FLOAT_WRITE   = 0x1015
  SFC_GET_SIMPLE_FORMAT_COUNT     = 0x1020
  SFC_GET_SIMPLE_FORMAT           = 0x1021
  SFC_GET_FORMAT_INFO             = 0x1028
  SFC_GET_FORMAT_MAJOR_COUNT      = 0x1030
  SFC_GET_FORMAT_MAJOR            = 0x1031
  SFC_GET_FORMAT_SUBTYPE_COUNT    = 0x1032
  SFC_GET_FORMAT_SUBTYPE          = 0x1033
  SFC_CALC_SIGNAL_MAX             = 0x1040
  SFC_CALC_NORM_SIGNAL_MAX        = 0x1041
  SFC_CALC_MAX_ALL_CHANNELS       = 0x1042
  SFC_CALC_NORM_MAX_ALL_CHANNELS  = 0x1043
  SFC_GET_SIGNAL_MAX              = 0x1044
  SFC_GET_MAX_ALL_CHANNELS        = 0x1045
  SFC_SET_ADD_PEAK_CHUNK          = 0x1050
  SFC_UPDATE_HEADER_NOW           = 0x1060
  SFC_SET_UPDATE_HEADER_AUTO      = 0x1061
  SFC_FILE_TRUNCATE               = 0x1080
  SFC_SET_RAW_START_OFFSET        = 0x1090
  SFC_SET_DITHER_ON_WRITE         = 0x10A0
  SFC_SET_DITHER_ON_READ          = 0x10A1
  SFC_GET_DITHER_INFO_COUNT       = 0x10A2
  SFC_GET_DITHER_INFO             = 0x10A3
  SFC_GET_EMBED_FILE_INFO         = 0x10B0
  SFC_SET_CLIPPING                = 0x10C0
  SFC_GET_CLIPPING                = 0x10C1
  SFC_GET_CUE_COUNT               = 0x10CD
  SFC_GET_CUE                     = 0x10CE
  SFC_SET_CUE                     = 0x10CF
  SFC_GET_INSTRUMENT              = 0x10D0
  SFC_SET_INSTRUMENT              = 0x10D1
  SFC_GET_LOOP_INFO               = 0x10E0
  SFC_GET_BROADCAST_INFO          = 0x10F0
  SFC_SET_BROADCAST_INFO          = 0x10F1
  SFC_GET_CHANNEL_MAP_INFO        = 0x1100
  SFC_SET_CHANNEL_MAP_INFO        = 0x1101
  SFC_RAW_DATA_NEEDS_ENDSWAP      = 0x1110
  # Support for Wavex Ambisonics Format
  SFC_WAVEX_SET_AMBISONIC         = 0x1200
  SFC_WAVEX_GET_AMBISONIC         = 0x1201
  # RF64 files can be set so that on-close, writable files that have less
  # than 4GB of data in them are converted to RIFF/WAV, as per EBU
  # recommendations.
  SFC_RF64_AUTO_DOWNGRADE         = 0x1210

  SFC_SET_VBR_ENCODING_QUALITY    = 0x1300
  SFC_SET_COMPRESSION_LEVEL       = 0x1301

  # Ogg format commands
  SFC_SET_OGG_PAGE_LATENCY_MS     = 0x1302
  SFC_SET_OGG_PAGE_LATENCY        = 0x1303
  SFC_GET_OGG_STREAM_SERIALNO     = 0x1306

  SFC_GET_BITRATE_MODE            = 0x1304
  SFC_SET_BITRATE_MODE            = 0x1305

  # Cart Chunk support
  SFC_SET_CART_INFO               = 0x1400
  SFC_GET_CART_INFO               = 0x1401

  # Opus files original samplerate metadata
  SFC_SET_ORIGINAL_SAMPLERATE     = 0x1500
  SFC_GET_ORIGINAL_SAMPLERATE     = 0x1501

  # Following commands for testing only.
  SFC_TEST_IEEE_FLOAT_REPLACE     = 0x6001

  # These SFC_SET_ADD_* values are deprecated and will disappear at some
  # time in the future. They currently do nothing and will continue to do
  # nothing.
  SFC_SET_ADD_HEADER_PAD_CHUNK    = 0x1051
  SFC_SET_ADD_DITHER_ON_WRITE     = 0x1070
  SFC_SET_ADD_DITHER_ON_READ      = 0x1071

  # String types that can be set and read from files. Not all file types
  # support this and even the file types which support one, may not support
  # all string types.
  SF_STR_TITLE                = 0x01
  SF_STR_COPYRIGHT            = 0x02
  SF_STR_SOFTWARE             = 0x03
  SF_STR_ARTIST               = 0x04
  SF_STR_COMMENT              = 0x05
  SF_STR_DATE                 = 0x06
  SF_STR_ALBUM                = 0x07
  SF_STR_LICENSE              = 0x08
  SF_STR_TRACKNUMBER          = 0x09
  SF_STR_GENRE                = 0x10

  # Use the following as the start and end index when doing metadata
  # transcoding.
  SF_STR_FIRST                = SF_STR_TITLE
  SF_STR_LAST                 = SF_STR_GENRE

  # True and false
  SF_FALSE                    = 0
  SF_TRUE                     = 1

  # Modes for opening files.
  SFM_READ                    = 0x10
  SFM_WRITE                   = 0x20
  SFM_RDWR                    = 0x30

  SF_AMBISONIC_NONE           = 0x40
  SF_AMBISONIC_B_FORMAT       = 0x41

  # Public error values. These are guaranteed to remain unchanged for the
  # duration of the library major version number.
  SF_ERR_NO_ERROR             = 0
  SF_ERR_UNRECOGNISED_FORMAT  = 1
  SF_ERR_SYSTEM               = 2
  SF_ERR_MALFORMED_FILE       = 3
  SF_ERR_UNSUPPORTED_ENCODING = 4

  # Channel map values (used with SFC_SET/GET_CHANNEL_MAP).
  SF_CHANNEL_MAP_INVALID                = 0
  SF_CHANNEL_MAP_MONO                   = 1
  SF_CHANNEL_MAP_LEFT                   = 2
  SF_CHANNEL_MAP_RIGHT                  = 3
  SF_CHANNEL_MAP_CENTER                 = 4
  SF_CHANNEL_MAP_FRONT_LEFT             = 5
  SF_CHANNEL_MAP_FRONT_RIGHT            = 6
  SF_CHANNEL_MAP_FRONT_CENTER           = 7
  SF_CHANNEL_MAP_REAR_CENTER            = 8
  SF_CHANNEL_MAP_REAR_LEFT              = 9
  SF_CHANNEL_MAP_REAR_RIGHT             = 10
  SF_CHANNEL_MAP_LFE                    = 11
  SF_CHANNEL_MAP_FRONT_LEFT_OF_CENTER   = 12
  SF_CHANNEL_MAP_FRONT_RIGHT_OF_CENTER  = 13
  SF_CHANNEL_MAP_SIDE_LEFT              = 14
  SF_CHANNEL_MAP_SIDE_RIGHT             = 15
  SF_CHANNEL_MAP_TOP_CENTER             = 16
  SF_CHANNEL_MAP_TOP_FRONT_LEFT         = 17
  SF_CHANNEL_MAP_TOP_FRONT_RIGHT        = 18
  SF_CHANNEL_MAP_TOP_FRONT_CENTER       = 19
  SF_CHANNEL_MAP_TOP_REAR_LEFT          = 20
  SF_CHANNEL_MAP_TOP_REAR_RIGHT         = 21
  SF_CHANNEL_MAP_TOP_REAR_CENTER        = 22
  SF_CHANNEL_MAP_AMBISONIC_B_W          = 23
  SF_CHANNEL_MAP_AMBISONIC_B_X          = 24
  SF_CHANNEL_MAP_AMBISONIC_B_Y          = 25
  SF_CHANNEL_MAP_AMBISONIC_B_Z          = 26
  SF_CHANNEL_MAP_MAX                    = 27

  # Bitrate mode values (for use with SFC_GET/SET_BITRATE_MODE)
  SF_BITRATE_MODE_CONSTANT    = 0
  SF_BITRATE_MODE_AVERAGE     = 1
  SF_BITRATE_MODE_VARIABLE    = 2

  # Enums and typedefs for adding dither on read and write.
  # Reserved for future implementation.
  SFD_DEFAULT_LEVEL           = 0
  SFD_CUSTOM_LEVEL            = 0x40000000
  SFD_NO_DITHER               = 500
  SFD_WHITE                   = 501
  SFD_TRIANGULAR_PDF          = 502

  # The loop mode field in SF_INSTRUMENT will be one of the following.
  SF_LOOP_NONE                = 800
  SF_LOOP_FORWARD             = 801
  SF_LOOP_BACKWARD            = 802
  SF_LOOP_ALTERNATING         = 803

  # sf_seek () uses the same values for whence (SEEK_SET, SEEK_CUR and
  # SEEK_END) as stdio.h function fseek ().
  SF_SEEK_SET                 = 0
  SF_SEEK_CUR                 = 1
  SF_SEEK_END                 = 2

  SF_COUNT_MAX                = (2**63) - 1
end
