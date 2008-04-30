# $Id$

require 'bitwise/packet'

module BitWise

class FloatField < Field

  CODE = {
    32 => ['e', 'g', 'f'], # little, big, native
    64 => ['E', 'G', 'D']
  }

  # call-seq:
  #    field.default = value
  #
  def default=( val )
    @opts[:default] = (val.nil? ? 0.0 : Float(val))
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

    i = case endian
        when :little; 0
        when :network, :big; 1
        when :native; 2
        else
          raise ArgumentError, "unknown endian option '#{endian}'"
        end

    raise AlignmentError, 'float values must be byte aligned' unless 0 == (offset % 8)
    unless [64, 32].include? @length
      raise AlignmentError, "float values must be 32 or 64 bits in length '#@length'"
    end

    code = CODE[@length][i]

    packet.class_eval do
      define_method(setter) {|val| @_values[index] = Float(val)}
      define_method(getter) {@_values.at(index)}
    end

    [code, 1]
  end
end  # class FloatField

module MetaPacket::ClassMethods

  # call-seq:
  #    float( name, length, opts = {} )
  #
  def float( *args )
    add_field(::BitWise::FloatField.new(*args))
  end
end

end  # module BitWise

# EOF
