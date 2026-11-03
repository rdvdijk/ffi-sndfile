# frozen_string_literal: true

module SndFile
  RSpec.describe Error do
    it "defines error classes descending from SndFileError" do
      [UnrecognisedFormatError, SystemError, MalformedFileError, UnsupportedEncodingError, ClosedFileError]
        .each { |error_class| expect(error_class.ancestors).to include(SndFileError) }
      expect(SndFileError.ancestors).to include(StandardError)
    end

    it "keeps the error number on the exception" do
      expect(SndFileError.new("boom", code: 42).code).to be 42
      expect(SndFileError.new("boom").code).to be_nil
    end

    describe ".check_error" do
      it "does not raise on SF_ERR_NO_ERROR" do
        expect { described_class.check_error(SF_ERR_NO_ERROR) }.not_to raise_error
      end

      it "ignores non-Integer values" do
        expect { described_class.check_error(nil) }.not_to raise_error
      end

      {
        SF_ERR_UNRECOGNISED_FORMAT => UnrecognisedFormatError,
        SF_ERR_SYSTEM => SystemError,
        SF_ERR_MALFORMED_FILE => MalformedFileError,
        SF_ERR_UNSUPPORTED_ENCODING => UnsupportedEncodingError
      }.each do |number, error_class|
        it "raises #{error_class} for error number #{number}" do
          expect { described_class.check_error(number) }
            .to raise_error(error_class) { |error| expect(error.code).to be number }
        end
      end

      it "raises a plain SndFileError for libsndfile's private error numbers" do
        expect { described_class.check_error(30) }.to raise_error do |error|
          expect(error.class).to be SndFileError
          expect(error.code).to be 30
        end
      end

      it "uses libsndfile's text for the error number" do
        expect { described_class.check_error(SF_ERR_UNRECOGNISED_FORMAT) }
          .to raise_error(UnrecognisedFormatError, Native.sf_error_number(SF_ERR_UNRECOGNISED_FORMAT))
      end

      it "prefers the file's own error message" do
        sndfile = FFI::Pointer.new(0x1234)
        allow(Native).to receive(:sf_strerror).with(sndfile).and_return("Writing to read-only file.")
        expect { described_class.check_error(30, sndfile) }.to raise_error(SndFileError, "Writing to read-only file.")
      end

      it "falls back to the number's text when the file reports no error" do
        sndfile = FFI::Pointer.new(0x1234)
        allow(Native).to receive(:sf_strerror).with(sndfile).and_return(Native.sf_error_number(0))
        expect { described_class.check_error(SF_ERR_SYSTEM, sndfile) }
          .to raise_error(SystemError, Native.sf_error_number(SF_ERR_SYSTEM))
      end

      it "falls back to a generic message when libsndfile has no text" do
        allow(Native).to receive_messages(sf_strerror: "", sf_error_number: nil)
        expect { described_class.check_error(77) }.to raise_error(SndFileError, "libsndfile error 77")
      end

      it "falls back to a generic message when reading the text fails" do
        allow(Native).to receive(:sf_strerror).and_raise(ArgumentError)
        allow(Native).to receive(:sf_error_number).and_raise(ArgumentError)
        expect { described_class.check_error(77, FFI::Pointer.new(0x1234)) }
          .to raise_error(SndFileError, "libsndfile error 77")
      end

      it "doesn't use the message of an earlier failed open" do
        expect { SoundFile.open(tmp_path("missing.wav")) }.to raise_error(SystemError, /No such file/)
        expect { described_class.check_error(SF_ERR_MALFORMED_FILE) }
          .to raise_error(MalformedFileError, Native.sf_error_number(SF_ERR_MALFORMED_FILE))
      end
    end

    describe ".check_sndfile" do
      it "raises the error libsndfile recorded for a file" do
        sndfile = FFI::Pointer.new(0x1234)
        allow(Native).to receive(:sf_error).with(sndfile).and_return(SF_ERR_MALFORMED_FILE)
        allow(Native).to receive(:sf_strerror).with(sndfile).and_return("Bad file.")
        expect { described_class.check_sndfile(sndfile) }.to raise_error(MalformedFileError, "Bad file.")
      end
    end

    describe ".raise_open_error" do
      it "raises the global error of a failed open" do
        expect { SoundFile.open(tmp_path("nope.wav")) }.to raise_error(SystemError, /nope\.wav|No such file/)
      end

      it "raises a SystemError when libsndfile recorded no error number" do
        allow(Native).to receive(:sf_error).with(nil).and_return(SF_ERR_NO_ERROR)
        allow(Native).to receive(:sf_strerror).with(nil).and_return("")
        expect { described_class.raise_open_error }.to raise_error(SystemError)
      end
    end
  end
end
