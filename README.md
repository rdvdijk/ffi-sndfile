# ffi-sndfile

Ruby FFI bindings for [libsndfile](https://libsndfile.github.io/libsndfile/), the library for reading and writing sound files: WAV, AIFF, FLAC, Ogg/Vorbis, Opus, MP3, CAF and many more.

See [CHANGELOG.md](CHANGELOG.md) for what changed.

## Installation

### Requirements

- Ruby 3.2 or newer
- libsndfile 1.0.28 or newer, including its development files:
  - Ubuntu / Debian: `sudo apt-get install libsndfile1-dev`
  - Fedora: `sudo dnf install libsndfile-devel`
  - Arch Linux: `sudo pacman -S libsndfile`
  - macOS (Homebrew): `brew install libsndfile`

Check your version with `pkg-config --modversion sndfile`. With libsndfile older than 1.0.28, `require "sndfile"` raises a `LoadError` that names the version it found. MP3 support (the `:mpeg` format and `bitrate_mode`) needs libsndfile 1.1.0 or newer, built with MPEG support.

### Gem Installation

Add to your Gemfile:

```ruby
gem "ffi-sndfile"
```

And run:

```bash
bundle install
```

Then load it with `require "sndfile"` (or `require "ffi-sndfile"`; Bundler's auto-require uses that one). The library lives in the `SndFile` module.

## Usage

### Reading a Sound File

`SndFile.open` (the same as `SndFile::SoundFile.open`) opens a file. With a block, it closes the file afterwards (also when the block raises) and returns the block's value:

```ruby
require "sndfile"

SndFile.open("song.flac") do |file|
  file.samplerate  # => 44100
  file.channels    # => 2
  file.frames      # => 9_261_000
  file.duration    # => 210.0 (seconds)
  file.format      # => #<SndFile::Format flac/pcm_16>

  # Read in buffers of 4096 frames
  file.each_buffer(4096) do |samples|
    # samples is a flat Array, channels interleaved: [left, right, left, right, ...]
  end
end
```

Samples are floats from -1.0 to 1.0 by default. Pass `type:` to get another sample type; libsndfile converts between it and the file's encoding:

| `type:` | Values |
|---|---|
| `:float` (default) | Floats, -1.0 to 1.0 |
| `:double` | Floats, -1.0 to 1.0 |
| `:short` | 16 bit integers, -32768 to 32767 |
| `:int` | 32 bit integers |

```ruby
SndFile.open("take.wav") do |file|
  file.read(1024)                 # up to 1024 frames as floats ([] at the end of the file)
  file.read(1024, type: :short)   # the next 1024 frames as 16 bit integers
  file.seek(0)                    # back to the first frame; also seek(n, :cur) and seek(-n, :end)
  file.read                       # everything up to the end of the file
end
```

Without a block, `open` returns the `SndFile::SoundFile`; call `close` when you're done. The file is also closed when it is garbage collected, but don't rely on that when writing: closing is what writes the final header.

### Writing a Sound File

Writing needs a sample rate, a channel count and a format. The format can come from the file name's extension:

```ruby
samples = Array.new(44_100) { |i| 0.5 * Math.sin(2 * Math::PI * 440 * i / 44_100) } # one second of A4

SndFile.open("a4.wav", :write, samplerate: 44_100, channels: 1) do |file|
  file.write(samples)  # => 44100 (frames written)
end
```

Or give it with `format:` (a major format such as `:wav` or `:flac`) and optionally `subtype:` (the encoding) and `endian:`:

```ruby
SndFile.open("a4.aiff", :write, format: :aiff, subtype: :pcm_24, samplerate: 48_000, channels: 2) do |file|
  file << [0.1, -0.1] << [0.2, -0.2]  # two stereo frames
end
```

Without `subtype:`, common formats use a sensible default: `:pcm_16` for WAV, AIFF, FLAC and the like, `:vorbis` for Ogg and `:mpeg_layer_iii` for MP3. An unknown name or a combination libsndfile can't write (such as `format: :wav, subtype: :vorbis`) raises `ArgumentError`. Open a file with `:rdwr` to read and write it, for example to append.

### Ogg/Vorbis with Vorbis Comments

String metadata (title, artist, ...) is written in the format's own way: as Vorbis comments in Ogg and FLAC files, as an INFO chunk in WAV files, and so on. Most formats need the strings, and encoder settings such as the quality, before the first audio is written, so pass them to `open` or set them first thing:

```ruby
SndFile.open("song.ogg", :write, samplerate: 44_100, channels: 2,
                                 strings: { title: "Heart of Gold", artist: "Neil Young" }) do |file|
  file.strings.album = "Harvest"
  file.strings[:date] = "1972"
  file.vbr_quality = 0.6  # 0.0 (smallest file) to 1.0 (best quality)

  file.write(samples)
end

SndFile.open("song.ogg") do |file|
  file.format        # => #<SndFile::Format ogg/vorbis>
  file.strings.title # => "Heart of Gold"
  file.strings.to_h  # => {title: "Heart of Gold", artist: "Neil Young", date: "1972", album: "Harvest"}
end
```

The strings are `title`, `copyright`, `software`, `artist`, `comment`, `date`, `album`, `license`, `tracknumber` (also `track_number`) and `genre`. They are read back as UTF-8. Setting a string after audio was written, or one the format doesn't support, raises `SndFile::SndFileError`.

Use `format: :ogg, subtype: :opus` (or a `.opus` file name) for Ogg/Opus.

### Files in Memory and Other IO Objects

Instead of a path, you can pass an IO-like object, such as a `StringIO`, a `File` or a socket. libsndfile reads and writes it through `#read`, `#write`, `#seek` and `#pos`. A format is needed for writing, since there is no file name to take it from:

```ruby
require "stringio"

io = StringIO.new(+"".b)
SndFile.open(io, :write, format: :ogg, samplerate: 44_100, channels: 1) { |file| file.write(samples) }
io.string  # => "OggS\x00\x02..."

io.rewind
SndFile.open(io) { |file| file.frames }  # => 44100
```

Exceptions raised by the IO object are raised again by the `SndFile` call that caused them.

### Other Settings

```ruby
file.compression_level = 0.8   # FLAC, Ogg, MP3: 0.0 (fastest) to 1.0 (smallest)
file.bitrate_mode = :variable  # MP3: :constant, :average or :variable
file.normalize_float = false   # read and write floats unscaled (default: -1.0..1.0)
file.signal_max                # the largest absolute sample value
file.update_header_now         # make a file being written readable already
file.truncate(1000)            # cut the file to 1000 frames
file.byterate                  # current bytes per second, or nil
file.log_info                  # libsndfile's log of opening the file
```

Every other libsndfile command is available through `file.command`, which takes an `SFC_*` constant or its name as a symbol and passes the data on, for example a `SndFile::Native::BroadcastInfo` struct for the Broadcast WAV `bext` chunk:

```ruby
bext = SndFile::Native::BroadcastInfo.new
bext.set_string(:description, "Field recording")

SndFile.open("field.wav", :write, samplerate: 48_000, channels: 2) do |file|
  file.command(:set_broadcast_info, bext)  # => 1 (SF_TRUE); before any audio is written
  file.write(samples)
end
```

### Formats

```ruby
SndFile::Format.new(:ogg, :vorbis).to_i                 # => 2097248 (SF_FORMAT_OGG | SF_FORMAT_VORBIS)
SndFile::Format.new(0x170002)                           # => #<SndFile::Format flac/pcm_16>
SndFile::Format.new(:flac).valid?(samplerate: 44_100, channels: 2)  # => true

SndFile.major_formats.map(&:name)   # => ["AIFF (Apple/SGI)", "AU (Sun/NeXT)", ...]
SndFile.subtypes.map(&:name)        # => ["Signed 8 bit PCM", "Signed 16 bit PCM", ...]
SndFile.simple_formats              # common combinations, each with its format, name and extension
SndFile::Formats.describe(:vorbis)  # => #<data SndFile::FormatDescription format=..., name="Vorbis", extension=nil>
```

The lists come from the loaded libsndfile, so they show what this installation supports.

### Errors

Every libsndfile error is raised as a subclass of `SndFile::SndFileError`, so `rescue SndFile::SndFileError` catches them all. The message is libsndfile's own error text, and `#code` is libsndfile's error number.

| Class | libsndfile error |
|---|---|
| `SndFile::UnrecognisedFormatError` | `SF_ERR_UNRECOGNISED_FORMAT`: not a sound file, or a format libsndfile can't read |
| `SndFile::SystemError` | `SF_ERR_SYSTEM`: an operating system error, such as a missing file |
| `SndFile::MalformedFileError` | `SF_ERR_MALFORMED_FILE`: the file is damaged |
| `SndFile::UnsupportedEncodingError` | `SF_ERR_UNSUPPORTED_ENCODING`: an encoding libsndfile can't decode |
| `SndFile::SndFileError` | any of libsndfile's other, internal errors |
| `SndFile::ClosedFileError` | the `SoundFile` was used after it was closed |

### libsndfile Version

`SndFile.version` describes the loaded libsndfile library:

```ruby
SndFile.version.to_s       # => "libsndfile-1.2.2"
SndFile.version.number     # => "1.2.2"
SndFile.version >= "1.1.0" # => true
```

### Threads

libsndfile calls that read or write a file (`open`, `read`, `write`, `seek`, `close`, ...) let other Ruby threads keep running while they wait on the disk.

### Low-level libsndfile Functions

Every function in `sndfile.h` is attached to `SndFile::Native`, an `FFI::Library`, for anything `SndFile::SoundFile` doesn't cover. Every struct is there too (`Native::Info` for `SF_INFO`, `Native::Instrument`, `Native::CartInfo`, `Native::ChunkInfo`, ...), and every constant is in `SndFile` (`SndFile::SF_FORMAT_OGG`, `SndFile::SFC_GET_LOG_INFO`, ...). Parameters for modes, string types, commands and seek origins also take symbols:

```ruby
info = SndFile::Native::Info.new
sndfile = SndFile::Native.sf_open("take.wav", :read, info)
info[:frames]                                   # => 1000
SndFile::Native.sf_get_string(sndfile, :title)  # => "Old Man"
SndFile::Native.sf_close(sndfile)               # => 0
```

`sf_open`, `sf_open_fd` and `sf_open_virtual` return a handle that closes itself when it is garbage collected, unless you close it with `Native.sf_close` first; they raise a `SndFile::SndFileError` instead of returning `NULL`. Otherwise these functions return libsndfile's error codes instead of raising, and their API follows libsndfile rather than this gem.

## Development

See [CONTRIBUTING.md](CONTRIBUTING.md) for how to set up the project, run the specs and which Ruby versions changes need to support.

## License

MIT License. See [LICENSE.txt](LICENSE.txt).
