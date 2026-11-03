# frozen_string_literal: true

module SndFile
  # Lets libsndfile read and write an IO-like object, such as a StringIO,
  # through sf_open_virtual. The object needs #read or #write, and #seek and
  # #pos for formats that seek, which most do when writing.
  #
  # Exceptions from the IO must not unwind through libsndfile, so they are
  # kept in #error, and SoundFile raises them again.
  class VirtualIO
    # For each SF_VIRTUAL_IO callback: the method that implements it and the
    # value it returns to libsndfile when the IO raises.
    CALLBACKS = {
      get_filelen: [:io_length, -1],
      seek: [:io_seek, -1],
      read: [:io_read, 0],
      write: [:io_write, 0],
      tell: [:io_tell, -1]
    }.freeze
    private_constant :CALLBACKS

    attr_reader :io, :struct, :error

    def initialize(io)
      @io = io
      @struct = Native::VirtualIO.new
      # The struct only holds C function pointers; keep the procs referenced
      # so they aren't garbage collected while libsndfile may call them.
      @callbacks = callbacks
      @callbacks.each { |name, callback| @struct[name] = callback }
    end

    # Raises (and clears) the exception an IO callback caught, if any.
    def raise_error!
      return unless @error

      error = @error
      @error = nil
      raise error
    end

    private

    # The procs ignore the user_data pointer libsndfile passes last.
    def callbacks
      CALLBACKS.transform_values do |(method_name, failure_value)|
        ->(*args) { guard(failure_value) { send(method_name, *args[0...-1]) } }
      end
    end

    def guard(failure_value)
      yield
    rescue StandardError => e
      @error ||= e
      failure_value
    end

    def io_length
      return io.size if io.respond_to?(:size)
      return io.stat.size if io.respond_to?(:stat)

      -1
    end

    def io_seek(offset, whence)
      io.seek(offset, whence)
      io.pos
    end

    def io_read(ptr, count)
      data = io.read(count)
      return 0 if data.nil? || data.empty?

      ptr.put_bytes(0, data)
      data.bytesize
    end

    def io_write(ptr, count)
      io.write(ptr.get_bytes(0, count))
    end

    def io_tell
      io.pos
    end
  end
end
