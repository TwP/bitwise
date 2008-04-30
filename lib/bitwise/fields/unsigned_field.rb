# $Id$

require 'bitwise/packet'

module BitWise

class UnsignedField < Field

  CODE = {
    8  => ['C']*3,          # little, big, native
    16 => ['v', 'n', 'S'],
    32 => ['V', 'N', 'L'],
    64 => [nil, nil, 'Q']
  }

  # call-seq:
  #
  def default=( val )
    @opts[:default] = Integer(val)
  end

  # call-seq:
  #    add_accessors_to( packet )
  #
  def add_accessors_to( packet )
    getter = self.getter
    setter = self.setter
    endian = @opts[:endian] || :network

    offset = packet.offset
    index = packet.index
    max = 2**@length

    i = case endian
        when :little; 0
        when :network, :big; 1
        when :native; 2
        else
          raise ArgumentError, "unknown endian option '#{endian}'"
        end

    raise ArgumentError, "offset cannot be negative '#{offset}'" if offset < 0
    if :little == endian
      raise AlignmentError, 'little endian values must be byte aligned' unless 0 == (offset % 8)
      raise AlignmentError, 'little endian values must have integer byte length' unless 0 == (@length % 8)
    end

    if (0 == offset % 8) && (c = CODE[@length]) && (code = c[i])
      packet.class_eval do
        define_method(setter) {|val| @_values[index] = Integer(val) % max}
        define_method(getter) {@_values.at index}
      end
      return [code, 1]
    end

    offset = packet.bit_string_offset
    length = @length

    packet.class_eval do
      define_method(setter) do |val|
        str = @_values[index] ||= ''
        BitString[str, offset, length, endian] = Integer(val) % max
      end

      define_method(getter) do
        str = @_values[index] ||= ''
        BitString[str, offset, length, endian]
      end
    end

    [length, nil]
  end

end  # class UnsignedField

module MetaPacket::ClassMethods

  # call-seq:
  #
  def unsigned( *args )
    add_field(::BitWise::UnsignedField.new(*args))
  end
end

end  # module BitWise

# EOF
