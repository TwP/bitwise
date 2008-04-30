# $Id$

require 'bitwise/packet'

module BitWise

class RestField < Field

  # call-seq:
  #    field.default = value
  #
  def default=( val )
    @opts[:default] = val.to_s
  end

  # call-seq:
  #    describe( :offset => nil ) {|ary| block}
  #
  # Yields to the given _block_ an array of five values that serves to
  # describe this field. If an offset is given, then it is used to determine
  # the byte offset of this field in a packet.
  #
  # With the RestField, the size will always be set to "var", and it will
  # not change the offset.
  #
  def describe( opts = {} )
    byte_offset = nil
    if opts.has_key? :offset
      byte_offset = '@%d' % (opts[:offset] / 8)
    end

    yield [byte_offset, self.class.field_name, @name.to_s, 'var', @description]
  end

  # call-seq:
  #    add_accessors_to( packet )
  #
  def add_accessors_to( packet )
    getter = self.getter
    setter = self.setter

    raise AlignmentError, "beginning the 'rest' field must fall on a byte boundary" unless 0 == (packet.offset % 8)

    packet.class_eval do
      define_method(setter) {|val| @_values[-1] = val.to_s}
      define_method(getter) {@_values.last}
    end

    nil
  end
end  # class RestField

class << Packet

  # call-seq:
  #    rest( name, opts = {} )
  #
  def rest( *args )
    unless @rest_field.nil?
      raise FieldError, "rest field already defined as '#{@rest_field.name}'"
    end

    rf = ::BitWise::RestField.new( *args )
    rf.add_accessors_to self
    @rest_field = rf
  end
end

end  # module BitWise

# EOF
