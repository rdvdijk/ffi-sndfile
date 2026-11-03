# frozen_string_literal: true

module SndFile
  # FFI::Struct definitions for the structs in sndfile.h, in the order of
  # that header. Field names follow the C names.
  module Native
    # Helpers for structs with fixed-size char arrays: read them as Ruby
    # strings (up to the first NUL) and write Ruby strings into them.
    module CharArrayFields
      # The char array +field+ as a String, up to the first NUL byte.
      def string(field)
        self[field].to_ptr.get_bytes(0, self[field].size).unpack1("Z*")
      end

      # Writes +value+ into the char array +field+, NUL-padded. A value may
      # fill the array exactly; a longer one raises ArgumentError.
      def set_string(field, value)
        bytes = value.to_s.b
        size = self[field].size
        raise ArgumentError, "#{field} is at most #{size} bytes, got #{bytes.bytesize}" if bytes.bytesize > size

        self[field].to_ptr.put_bytes(0, bytes.ljust(size, "\0"))
        value
      end
    end

    # SF_INFO: passed to sf_open, which fills it in when reading and reads
    # it when writing.
    class Info < FFI::Struct
      layout :frames,     :int64,
             :samplerate, :int,
             :channels,   :int,
             :format,     :int,
             :sections,   :int,
             :seekable,   :int
    end

    # SF_FORMAT_INFO: describes a format (SFC_GET_FORMAT_INFO and friends).
    class FormatInfo < FFI::Struct
      layout :format,    :int,
             :name,      :string,
             :extension, :string
    end

    # SF_DITHER_INFO (reserved for future use by libsndfile).
    class DitherInfo < FFI::Struct
      layout :type,  :int,
             :level, :double,
             :name,  :string
    end

    # SF_EMBED_FILE_INFO: where a sound file sits inside a larger file.
    class EmbedFileInfo < FFI::Struct
      layout :offset, :int64,
             :length, :int64
    end

    # SF_CUE_POINT: one cue marker.
    class CuePoint < FFI::Struct
      include CharArrayFields

      layout :indx,          :int32,
             :position,      :uint32,
             :fcc_chunk,     :int32,
             :chunk_start,   :int32,
             :block_start,   :int32,
             :sample_offset, :uint32,
             :name,          [:char, 256]
    end

    # SF_CUES: up to 100 cue markers (SFC_GET_CUE / SFC_SET_CUE).
    class Cues < FFI::Struct
      MAX_CUE_POINTS = 100

      layout :cue_count,  :uint32,
             :cue_points, [CuePoint, MAX_CUE_POINTS]
    end

    # SF_INSTRUMENT: sampler instrument data (SFC_GET/SET_INSTRUMENT).
    class Instrument < FFI::Struct
      # One entry of SF_INSTRUMENT's loops array.
      class Loop < FFI::Struct
        layout :mode,  :int,
               :start, :uint32,
               :end,   :uint32,
               :count, :uint32
      end

      MAX_LOOPS = 16

      layout :gain,        :int,
             :basenote,    :char,
             :detune,      :char,
             :velocity_lo, :char,
             :velocity_hi, :char,
             :key_lo,      :char,
             :key_hi,      :char,
             :loop_count,  :int,
             :loops,       [Loop, MAX_LOOPS]
    end

    # SF_LOOP_INFO: loop/tempo information (SFC_GET_LOOP_INFO).
    class LoopInfo < FFI::Struct
      layout :time_sig_num, :short,
             :time_sig_den, :short,
             :loop_mode,    :int,
             :num_beats,    :int,
             :bpm,          :float,
             :root_key,     :int,
             :future,       [:int, 6]
    end

    # SF_BROADCAST_INFO: the Broadcast WAV "bext" chunk, with 256 bytes of
    # coding history (SFC_GET/SET_BROADCAST_INFO).
    class BroadcastInfo < FFI::Struct
      include CharArrayFields

      layout :description,            [:char, 256],
             :originator,             [:char, 32],
             :originator_reference,   [:char, 32],
             :origination_date,       [:char, 10],
             :origination_time,       [:char, 8],
             :time_reference_low,     :uint32,
             :time_reference_high,    :uint32,
             :version,                :short,
             :umid,                   [:char, 64],
             :loudness_value,         :int16,
             :loudness_range,         :int16,
             :max_true_peak_level,    :int16,
             :max_momentary_loudness, :int16,
             :max_shortterm_loudness, :int16,
             :reserved,               [:char, 180],
             :coding_history_size,    :uint32,
             :coding_history,         [:char, 256]
    end

    # SF_CART_TIMER: one post timer of SF_CART_INFO.
    class CartTimer < FFI::Struct
      include CharArrayFields

      layout :usage, [:char, 4],
             :value, :int32
    end

    # SF_CART_INFO: the AES46 "cart" chunk, with 256 bytes of tag text
    # (SFC_GET/SET_CART_INFO).
    class CartInfo < FFI::Struct
      include CharArrayFields

      layout :version,              [:char, 4],
             :title,                [:char, 64],
             :artist,               [:char, 64],
             :cut_id,               [:char, 64],
             :client_id,            [:char, 64],
             :category,             [:char, 64],
             :classification,       [:char, 64],
             :out_cue,              [:char, 64],
             :start_date,           [:char, 10],
             :start_time,           [:char, 8],
             :end_date,             [:char, 10],
             :end_time,             [:char, 8],
             :producer_app_id,      [:char, 64],
             :producer_app_version, [:char, 64],
             :user_def,             [:char, 64],
             :level_reference,      :int32,
             :post_timers,          [CartTimer, 8],
             :reserved,             [:char, 276],
             :url,                  [:char, 1024],
             :tag_text_size,        :uint32,
             :tag_text,             [:char, 256]
    end

    # SF_VIRTUAL_IO: the callbacks sf_open_virtual uses instead of a file.
    # Every callback gets the user_data pointer passed to sf_open_virtual.
    class VirtualIO < FFI::Struct
      layout :get_filelen, callback([:pointer], :int64),
             :seek,        callback(%i[int64 int pointer], :int64),
             :read,        callback(%i[pointer int64 pointer], :int64),
             :write,       callback(%i[pointer int64 pointer], :int64),
             :tell,        callback([:pointer], :int64)
    end

    # SF_CHUNK_INFO: a chunk of a sound file (sf_set_chunk and the chunk
    # iterator functions).
    class ChunkInfo < FFI::Struct
      include CharArrayFields

      layout :id,      [:char, 64],
             :id_size, :uint,
             :datalen, :uint,
             :data,    :pointer
    end
  end
end
