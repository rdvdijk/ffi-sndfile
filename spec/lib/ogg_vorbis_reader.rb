# frozen_string_literal: true

# A minimal Ogg/Vorbis parser, independent of libsndfile, so the specs can
# check that the files libsndfile writes are what other players read.
#
# It checks every page's capture pattern and CRC, reassembles the packets
# of the first logical stream, and decodes the Vorbis identification and
# comment headers. See https://xiph.org/ogg/doc/framing.html and
# https://xiph.org/vorbis/doc/Vorbis_I_spec.html (section 5).
class OggVorbisReader
  class FormatError < StandardError; end

  Page = Struct.new(:header_type, :granule_position, :serial, :sequence, :segments, :body) do
    def continued? = header_type.anybits?(0x01)
    def first? = header_type.anybits?(0x02)
    def last? = header_type.anybits?(0x04)
  end

  # Ogg's CRC-32: polynomial 0x04c11db7, not reflected, initial value 0.
  CRC_TABLE = Array.new(256) do |byte|
    crc = byte << 24
    8.times { crc = crc.anybits?(0x80000000) ? ((crc << 1) ^ 0x04c11db7) : (crc << 1) }
    crc & 0xffffffff
  end.freeze

  def self.crc32(data)
    data.each_byte.reduce(0) do |crc, byte|
      ((crc << 8) & 0xffffffff) ^ CRC_TABLE[((crc >> 24) ^ byte) & 0xff]
    end
  end

  attr_reader :pages, :packets

  def initialize(data)
    @data = data.b
    @pages = parse_pages
    @packets = assemble_packets
  end

  def self.read(path)
    new(File.binread(path))
  end

  # The identification header: channels, sample rate and bitrates.
  def identification
    packet = vorbis_header(0, 1)
    _version, channels, rate, maximum, nominal, minimum = packet.unpack("@7 V C V l< l< l<")
    { channels: channels, samplerate: rate, bitrate_maximum: maximum, bitrate_nominal: nominal,
      bitrate_minimum: minimum }
  end

  # The vendor string of the comment header.
  def vendor
    comment_header.first
  end

  # The user comments as [field, value] pairs, in file order. Field names
  # are upper-cased (Vorbis comment field names are case-insensitive).
  def comments
    comment_header.last
  end

  # The comments as a Hash of field name => Array of values.
  def comment_hash
    comments.group_by(&:first).transform_values { |pairs| pairs.map(&:last) }
  end

  # The granule position of the last page: the total number of frames.
  def total_frames
    pages.last.granule_position
  end

  private

  def parse_pages
    pages = []
    offset = 0
    offset = parse_page(offset, pages) while offset < @data.bytesize
    raise FormatError, "no Ogg pages" if pages.empty?

    pages
  end

  def parse_page(offset, pages)
    header = @data.byteslice(offset, 27)
    raise FormatError, "missing OggS capture pattern at #{offset}" unless header&.start_with?("OggS")

    version, type, granule, serial, sequence, crc, count = header.unpack("@4 C C q< V V V C")
    raise FormatError, "unknown Ogg version #{version}" unless version.zero?

    segments = @data.byteslice(offset + 27, count).bytes
    length = 27 + count + segments.sum
    check_crc(offset, length, crc)
    pages << Page.new(type, granule, serial, sequence, segments, @data.byteslice(offset + 27 + count, segments.sum))
    offset + length
  end

  def check_crc(offset, length, expected)
    page = @data.byteslice(offset, length).dup
    page[22, 4] = "\0\0\0\0"
    actual = self.class.crc32(page)
    return if actual == expected

    raise FormatError, format("bad CRC on page at %<offset>d: %<actual>08x != %<expected>08x",
                              offset: offset, actual: actual, expected: expected)
  end

  def assemble_packets
    serial = pages.first.serial
    packets = []
    current = +""
    pages.select { |page| page.serial == serial }.each do |page|
      position = 0
      page.segments.each do |size|
        current << page.body.byteslice(position, size)
        position += size
        next if size == 255

        packets << current
        current = +""
      end
    end
    packets
  end

  def vorbis_header(index, type)
    packet = packets.fetch(index) { raise FormatError, "missing Vorbis header packet #{index}" }
    unless packet.start_with?("#{[type].pack("C")}vorbis")
      raise FormatError, "packet #{index} is not a Vorbis header of type #{type}"
    end

    packet
  end

  def comment_header
    @comment_header ||= begin
      packet = vorbis_header(1, 3)
      position = 7
      read = lambda do
        length = packet.unpack1("V", offset: position)
        packet.byteslice(position + 4, length).tap { position += 4 + length }
      end
      vendor = read.call.force_encoding(Encoding::UTF_8)
      count = packet.unpack1("V", offset: position)
      position += 4
      comments = Array.new(count) do
        field, value = read.call.force_encoding(Encoding::UTF_8).split("=", 2)
        [field.upcase, value]
      end
      raise FormatError, "comment header framing bit not set" unless packet.getbyte(position).anybits?(1)

      [vendor, comments]
    end
  end
end
