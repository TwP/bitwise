# $Id$

require 'bitwise/packet'

module BitWise

class TextField < Field

  # call-seq:
  #    field.default = value
  #
  def default=( val )
    @opts[:default] = val.to_s
  end

  # call-seq:
  #    add_accessors_to( packet )
  #
  def add_accessors_to( packet )
    getter = self.getter
    setter = self.setter

    offset = packet.offset
    index = packet.index

    raise AlignmentError, 'text values must be byte aligned' unless 0 == offset % 8
    raise AlignmentError, 'text values must have integer byte length' unless 0 == @length % 8

    packet.class_eval do
      define_method(setter) {|val| @_values[index] = val.to_s}
      define_method(getter) {@_values.at(index)}
    end

    ["A#{@length/8}", 1]
  end
end  # class TextField

module MetaPacket::ClassMethods

  # call-seq:
  #    text( name, length, opts = {} )
  #
  def text( *args )
    add_field(::BitWise::TextField.new(*args))
  end
end

end  # module BitWise

# EOF
