# $Id$

require 'bitwise/packet'

module BitWise

class CharField < Field

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

    raise AlignmentError, 'char values must be byte aligned' unless 0 == offset % 8
    raise AlignmentError, 'char values must have integer byte length' unless 0 == @length % 8

    packet.class_eval do
      define_method(setter) {|val| @_values[index] = val.to_s}
      define_method(getter) {@_values.at(index)}
    end

    ["a#{@length/8}", 1]
  end
end  # class CharField

module MetaPacket::ClassMethods

  # call-seq:
  #    char( name, length, opts = {} )
  #
  def char( *args )
    add_field(::BitWise::CharField.new(*args))
  end
end

end  # module BitWise

# EOF
