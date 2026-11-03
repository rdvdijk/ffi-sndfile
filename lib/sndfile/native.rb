# frozen_string_literal: true

require "sndfile/constants"
require "sndfile/library_version"

module SndFile
  # The libsndfile bindings: an FFI::Library with every function in
  # sndfile.h, plus the structs and enums those functions use.
  module Native
    extend FFI::Library

    ffi_lib ["sndfile", "libsndfile.so.1", "libsndfile.1.dylib", "libsndfile-1"]

    typedef :pointer, :sndfile
    typedef :int64, :sf_count_t

    # Attached first, so the version check below can run before the other
    # functions: attaching a function that an older libsndfile lacks would
    # fail with an unclear FFI::NotFoundError.
    attach_function :sf_version_string, [], :string
    LibraryVersion.ensure_supported!
  end
end

require "sndfile/native/enums"
require "sndfile/native/structs"
require "sndfile/native/handle"
require "sndfile/native/functions"
