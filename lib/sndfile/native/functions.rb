# frozen_string_literal: true

module SndFile
  # attach_function declarations for every function in sndfile.h.
  module Native
    # These `attach_function` declarations are in the order of sndfile.h, with
    # its comments. Parameters that take SFM_*, SF_STR_*, SFC_* or SF_SEEK_*
    # values use the FFI enums from enums.rb, so they accept symbols such as
    # :read or :title as well as the integer constants.
    # sf_open, sf_open_fd and sf_open_virtual return a Handle, which closes
    # itself when it is garbage collected, and raise a SndFileError instead of
    # returning NULL.
    # Calls that read or write the file are attached with `blocking: true` so
    # they release Ruby's GVL; pass them an FFI::MemoryPointer, never a Ruby
    # string's memory.

    # Open the specified file for read, write or both. On error, this will
    # return a NULL pointer. To find the error number, pass a NULL SNDFILE
    # to sf_strerror ().
    # All calls to sf_open() should be matched with a call to sf_close().
    attach_function :sf_open, [:string, :sf_mode, Info.by_ref], Handle, blocking: true

    # Use the existing file descriptor to create a SNDFILE object. If close_desc
    # is TRUE, the file descriptor will be closed when sf_close() is called. If
    # it is FALSE, the descriptor will not be closed.
    # When passed a descriptor like this, the library will assume that the start
    # of file header is at the current file offset. This allows sound files within
    # larger container files to be read and/or written.
    attach_function :sf_open_fd, [:int, :sf_mode, Info.by_ref, :int], Handle, blocking: true

    attach_function :sf_open_virtual, [VirtualIO.by_ref, :sf_mode, Info.by_ref, :pointer], Handle

    # sf_error () returns a error number which can be translated to a text
    # string using sf_error_number().
    attach_function :sf_error, [:sndfile], :int

    # sf_strerror () returns to the caller a pointer to the current error message for
    # the given SNDFILE.
    attach_function :sf_strerror, [:sndfile], :string

    # sf_error_number () allows the retrieval of the error string for each internal
    # error number.
    attach_function :sf_error_number, [:int], :string

    # The following two error functions are deprecated but they will remain in the
    # library for the foreseeable future. The function sf_strerror() should be used
    # in their place.
    attach_function :sf_perror, [:sndfile], :int
    attach_function :sf_error_str, %i[sndfile pointer size_t], :int

    # Allow the caller to retrieve information from or change aspects of the
    # library behaviour.
    attach_function :sf_command, %i[sndfile sf_command pointer int], :int

    # Return TRUE if fields of the SF_INFO struct are a valid combination of values.
    attach_function :sf_format_check, [Info.by_ref], :int

    # Seek within the waveform data chunk of the SNDFILE.
    # An offset of zero with whence set to SEEK_SET will position the
    # read / write pointer to the first data sample.
    # On success sf_seek returns the current position in (multi-channel)
    # samples from the start of the file.
    # On error all of these functions return -1.
    attach_function :sf_seek, %i[sndfile sf_count_t sf_seek_whence], :sf_count_t, blocking: true

    # Functions for retrieving and setting string data within sound files.
    # Not all file types support this features; AIFF and WAV do.
    # On error, sf_set_string() returns non-zero while sf_get_string()
    # returns NULL.
    attach_function :sf_set_string, %i[sndfile sf_str string], :int
    attach_function :sf_get_string, %i[sndfile sf_str], :string

    # Return the library version string.
    # (sf_version_string is attached in native.rb, before the version check)

    # Return the current byterate at this point in the file. The byte rate in this
    # case is the number of bytes per second of audio data.
    # Returns -1 for unknown.
    attach_function :sf_current_byterate, [:sndfile], :int

    # Functions for reading/writing the waveform data of a sound file.
    attach_function :sf_read_raw, %i[sndfile pointer sf_count_t], :sf_count_t, blocking: true
    attach_function :sf_write_raw, %i[sndfile pointer sf_count_t], :sf_count_t, blocking: true

    # Functions for reading and writing the data chunk in terms of frames.
    # The number of items actually read/written = frames * number of channels.
    # All of these read/write function return number of frames read/written.
    attach_function :sf_readf_short, %i[sndfile pointer sf_count_t], :sf_count_t, blocking: true
    attach_function :sf_writef_short, %i[sndfile pointer sf_count_t], :sf_count_t, blocking: true

    attach_function :sf_readf_int, %i[sndfile pointer sf_count_t], :sf_count_t, blocking: true
    attach_function :sf_writef_int, %i[sndfile pointer sf_count_t], :sf_count_t, blocking: true

    attach_function :sf_readf_float, %i[sndfile pointer sf_count_t], :sf_count_t, blocking: true
    attach_function :sf_writef_float, %i[sndfile pointer sf_count_t], :sf_count_t, blocking: true

    attach_function :sf_readf_double, %i[sndfile pointer sf_count_t], :sf_count_t, blocking: true
    attach_function :sf_writef_double, %i[sndfile pointer sf_count_t], :sf_count_t, blocking: true

    # Functions for reading and writing the data chunk in terms of items.
    # Otherwise similar to above.
    # All of these read/write function return number of items read/written.
    attach_function :sf_read_short, %i[sndfile pointer sf_count_t], :sf_count_t, blocking: true
    attach_function :sf_write_short, %i[sndfile pointer sf_count_t], :sf_count_t, blocking: true

    attach_function :sf_read_int, %i[sndfile pointer sf_count_t], :sf_count_t, blocking: true
    attach_function :sf_write_int, %i[sndfile pointer sf_count_t], :sf_count_t, blocking: true

    attach_function :sf_read_float, %i[sndfile pointer sf_count_t], :sf_count_t, blocking: true
    attach_function :sf_write_float, %i[sndfile pointer sf_count_t], :sf_count_t, blocking: true

    attach_function :sf_read_double, %i[sndfile pointer sf_count_t], :sf_count_t, blocking: true
    attach_function :sf_write_double, %i[sndfile pointer sf_count_t], :sf_count_t, blocking: true

    # Close the SNDFILE and clean up all memory allocations associated with this
    # file.
    # Returns 0 on success, or an error number.
    # (Attached as sf_close_pointer. Native.sf_close also stops a Handle from
    # being closed a second time when it is garbage collected.)
    attach_function :sf_close_pointer, :sf_close, [:sndfile], :int, blocking: true

    def self.sf_close(sndfile)
      sndfile.autorelease = false if sndfile.is_a?(Handle)
      sf_close_pointer(sndfile)
    end

    # If the file is opened SFM_WRITE or SFM_RDWR, call fsync() on the file
    # to force the writing of data to disk. If the file is opened SFM_READ
    # no action is taken.
    attach_function :sf_write_sync, [:sndfile], :void, blocking: true

    # The function sf_wchar_open() is Windows Only!
    # Open a file passing in a Windows Unicode filename. Otherwise, this is
    # the same as sf_open().
    attach_function :sf_wchar_open, [:pointer, :sf_mode, Info.by_ref], Handle, blocking: true if FFI::Platform.windows?

    # Getting and setting of chunks from within a sound file.
    #
    # These functions allow the getting and setting of chunks within a sound file
    # (for those formats which allow it).

    # Set the specified chunk info (must be done before any audio data is written
    # to the file). This will fail for format specific reserved chunks.
    # The chunk_info->data pointer must be valid until the file is closed.
    # Returns SF_ERR_NO_ERROR on success or non-zero on failure.
    attach_function :sf_set_chunk, [:sndfile, ChunkInfo.by_ref], :int

    # Get an iterator for all chunks matching chunk_info.
    # If chunk_info is NULL, an iterator to all chunks in the SNDFILE* handle
    #     is returned.
    # If no matching chunks are found in the sndfile, NULL is returned.
    # The memory for the iterator belongs to the SNDFILE* handle and is freed when
    # sf_close() is called.
    attach_function :sf_get_chunk_iterator, [:sndfile, ChunkInfo.by_ref], :pointer

    # Iterate through chunks by incrementing the iterator.
    # If iterator points to the last chunk, this will free all resources
    #      associated with iterator and return NULL.
    attach_function :sf_next_chunk_iterator, [:pointer], :pointer

    # Get the size of the specified chunk.
    # If the specified chunk exists, the size will be returned in the
    #      datalen field of the SF_CHUNK_INFO struct.
    # The function will return SF_ERR_NO_ERROR on success or non-zero on
    # failure.
    attach_function :sf_get_chunk_size, [:pointer, ChunkInfo.by_ref], :int

    # Get the specified chunk data.
    # If the specified chunk exists, up to chunk_info->datalen bytes of
    #      the chunk data will be copied into the chunk_info->data buffer
    #      (allocated by the caller).
    # The function will return SF_ERR_NO_ERROR on success or non-zero on
    # failure.
    attach_function :sf_get_chunk_data, [:pointer, ChunkInfo.by_ref], :int
  end
end
