# frozen_string_literal: true

# Exception classes for libsndfile errors.
module SndFile
  # Base class of every error this gem raises for libsndfile. #code is
  # libsndfile's error number (see sf_error), or nil when there is none.
  class SndFileError < StandardError
    attr_reader :code

    def initialize(message = nil, code: nil)
      super(message)
      @code = code
    end
  end

  class UnrecognisedFormatError < SndFileError; end
  class SystemError < SndFileError; end
  class MalformedFileError < SndFileError; end
  class UnsupportedEncodingError < SndFileError; end

  # Raised when a SoundFile is used after it was closed.
  class ClosedFileError < SndFileError; end

  # Maps libsndfile's error numbers to exception classes.
  module Error
    # libsndfile's public error numbers. It also has many private numbers
    # (which may change between versions); those raise a plain SndFileError.
    ERROR_CLASSES = {
      SF_ERR_UNRECOGNISED_FORMAT => UnrecognisedFormatError,
      SF_ERR_SYSTEM => SystemError,
      SF_ERR_MALFORMED_FILE => MalformedFileError,
      SF_ERR_UNSUPPORTED_ENCODING => UnsupportedEncodingError
    }.freeze

    # Raises the matching SndFileError for a non-zero libsndfile error
    # number. The message is the file's error text (sf_strerror) when
    # +sndfile+ is given, otherwise libsndfile's text for the number.
    def self.check_error(error_number, sndfile = nil)
      return unless error_number.is_a?(Integer) && error_number != SF_ERR_NO_ERROR

      raise_error(error_number, sndfile ? file_message(sndfile) : nil)
    end

    # Raises when libsndfile has recorded an error for +sndfile+ (sf_error).
    def self.check_sndfile(sndfile)
      check_error(Native.sf_error(sndfile), sndfile)
    end

    # Raises the error of a failed sf_open, sf_open_fd or sf_open_virtual,
    # which libsndfile keeps in global state (sf_error(NULL)). That state is
    # not cleared, so only call this right after the failure.
    def self.raise_open_error
      error_number = Native.sf_error(nil)
      error_number = SF_ERR_SYSTEM if error_number == SF_ERR_NO_ERROR
      raise_error(error_number, file_message(nil))
    end

    def self.raise_error(error_number, message)
      message ||= number_message(error_number) || "libsndfile error #{error_number}"
      raise ERROR_CLASSES.fetch(error_number, SndFileError).new(message, code: error_number)
    end

    # sf_strerror's text, unless it says there is no error. It is more
    # specific than sf_error_number's, e.g. it names the missing file.
    def self.file_message(sndfile)
      message = Native.sf_strerror(sndfile)
      message unless message.nil? || message.empty? || message == number_message(SF_ERR_NO_ERROR)
    rescue StandardError
      nil
    end

    def self.number_message(error_number)
      message = Native.sf_error_number(error_number)
      message unless message.nil? || message.empty?
    rescue StandardError
      nil
    end
    private_class_method :raise_error, :file_message, :number_message
  end
end
