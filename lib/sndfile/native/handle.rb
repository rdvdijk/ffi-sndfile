# frozen_string_literal: true

module SndFile
  module Native
    # An owned SNDFILE* handle, as returned by Native.sf_open, sf_open_fd and
    # sf_open_virtual. It is closed with sf_close when it is garbage
    # collected, unless it was closed before (see SoundFile#close).
    class Handle < FFI::AutoPointer
      def self.release(ptr)
        Native.sf_close_pointer(ptr)
      end

      # Called by FFI to wrap the pointer that the sf_open functions return.
      # They return NULL when the file can't be opened; this raises the
      # matching SndFileError with libsndfile's message instead.
      def self.from_native(ptr, ctx)
        Error.raise_open_error if ptr.null?

        super
      end
    end
  end
end
