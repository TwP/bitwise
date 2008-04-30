# $Id$

module BitWise

# The BitString module is used to get and set integer values from a String
# using bit offsets and lengths (as opposed to byte offsets and lengths).
# This module supports reading and writing little endian and big endian
# values.
#
module BitString
class << self
  # call-seq:
  #    BitString[ string, fixnum ]            => Integer
  #    BitString[ string, fixnum, fixnum ]    => Integer
  #    BitString[ string, range ]             => Integer
  #
  # Returns bits from the _string_ as an integer. The bits to return are
  # given as a bit offset into the string and an optional length or as a
  # range.
  #
  # If an integer is given, it is treated as the bit offset into the string.
  # Without a length, only a single bit is read. If a length is given, then
  # that many bits are read. Negative values are not allowed for the offset
  # or length.
  #
  # If a range is given, then it is used to identify the starting bit and
  # the ending bit. Negative values are not allowed in the range.
  #
  # Optionally, and endianness can be specified as a final argument. The
  # recognized values are :little, :nework, and :big. The latter two are
  # synonyms. Little endian values must be byte aligned, and they must have
  # integer byte length.
  #
  def []( str, *args )
    raise ArgumentError, 'expecting a String' unless String === str

    offset, length, endian = parse_args(args)

    first = offset / 8                # the first byte in the string
    last = (offset + length - 1) / 8  # the last byte in the string

    raise ArgumentError, "not enough bits in string" if last >= str.length

    # big and little endian values must be handled separately
    if :little == endian
      val = 0
      str.slice(first..last).reverse!.each_byte do |b|
        val <<= 8
        val += b
      end
      val

    # :network or :big
    else
      head = 0xFF >> (offset % 8)     # for masking off leading bits
      tail = (offset + length) % 8    # for shifting off the trailing bits
      tail = 8 - tail unless tail == 0

      val = str[first] & head         # mask off the leading bits

      # iterate over the remaining bytes and add them to our value
      if first < last
        str.slice((first+1)..last).each_byte do |b|
          val <<= 8
          val += b
        end
      end
      
      val >> tail   # shift off the trailing bits
    end
  end

  # call-seq:
  #    BitString[ string, fixnum ] = Integer
  #    BitString[ string, fixnum, fixnum ] = Integer
  #    BitString[ string, range ] = Integer
  #
  # Sets the given integer as a series of bits in the _string_. The bits to
  # set are identified using a bit offset and an optional length. If the
  # size of the integer is larger than the number of bits, the integer will
  # be truncaed.
  #
  # Regarding the bit specification, if an integer is given, it is treated
  # as the bit offset into the string. Without a length, only a single bit
  # is set. If a length is given, then that many bits are set. Negative
  # values are not allowed for the offset or length.
  #
  # If a range is given, then it is used to identify the starting bit and
  # the ending bit. Negative values are not allowed in the range.
  #
  # Optionally, and endianness can be specified as a final argument. The
  # recognized values are :little, :nework, and :big. The latter two are
  # synonyms. Little endian values must be byte aligned, and they must have
  # integer byte length.
  #
  def []=( str, *args )
    raise ArgumentError, 'expecting a String' unless String === str

    val = Integer(args.pop)
    offset, length, endian = parse_args(args)

    first = offset / 8                 # the first byte in the string
    last = (offset + length - 1) / 8   # the last byte in the string

    # grow the string to hold the value
    str << "\000" * (last - str.length + 1) if last >= str.length

    # big and little endian values must be handled separately
    if :little == endian
      first.upto last do |b|
        str[b] = val & 0xff
        val >>= 8
      end

    # :network or :big
    else
      head = 0xFF >> (offset % 8)      # for masking off leading bits
      tail = (offset + length) % 8     # for shifting off the trailing bits
      tail = 8 - tail unless tail == 0
      tm = 0xFF >> (8 - tail)          # for masking the trailing bits

      if last == first
        tmp = str[first] & tm
        tmp += (val << tail) & 0xFF
        str[first] = (str[first] & ~head) + (tmp & head)
      else
        str[last] &= tm
        str[last] += (val << tail) & 0xFF
        val >>= 8 - tail

        (last-1).downto(first+1) do |b|
          str[b] = val & 0xFF
          val >>= 8
        end

        str[first] = (str[first] & ~head) + (val & head)
      end
    end
  end


  private

  # call-seq:
  #    parse_args( ary )
  #
  # Given an array of arguments this method will parse out the endianness,
  # the offset, and the length. These will be returned as an array:
  #
  #    [offset, length, endian]
  #
  def parse_args( args )
    endian = (args.last.instance_of?(Symbol) ? args.pop : :big)
    offset, length = args

    case offset
    when Fixnum
      length ||= 1
    when Range
      r = offset
      offset = r.first
      length = r.last - r.first
      length += 1 unless r.exclude_end?
    else
      raise ArgumentError, "expecing a range or an offset/length"
    end

    raise RangeError, "offset cannot be negative '#{offset}'" if offset < 0
    raise RangeError, "length must be greather than zero '#{length}'" if length <= 0

    if :little == endian
      raise ArgumentError, 'little endian values must be byte aligned' unless 0 == (offset % 8)
      raise ArgumentError, 'little endian values must have integer byte length' unless 0 == (length % 8)
    end

    [offset, length, endian]
  end

end  # class << self
end  # class BitString
end  # module BitWise

# EOF
