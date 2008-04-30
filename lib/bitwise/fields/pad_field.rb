# $Id$

require 'bitwise/packet'

module BitWise

class PadField < Field

  # call-seq:
  #    PadField.new( )
  #
  def initialize( *args )
    super
    @description, @name = @name.to_s, nil
    @setter, @getter = :pad=, :pad
    @opts[:unique] = false
  end

  # call-seq:
  #    describe( :offset => nil ) {|ary| block}
  #
  # Yields to the given _block_ an array of five values that serves to
  # describe this field. If an offset is given, then it is used to determine
  # the byte offset of this field in a packet.
  #
  # With the PadField, the name will always be set to +nil+.
  #
  def describe( opts = {} )
    super do |ary|
      ary[2] = nil
      yield ary
    end
  end

  # call-seq:
  #    add_accessors_to( packet )
  #
  def add_accessors_to( packet )

    unless packet.private_method_defined? :pad
      packet.class_eval <<-CODE
        private
        def pad() nil end
        def pad=(val) nil end
      CODE
    end

    offset = packet.offset
    return ["x#{@length/8}", 0] if (0 == offset % 8) && (0 == @length % 8)
    [@length, nil]
  end

  # call-seq:
  #    inspect_in( packet )
  #
  def inspect_in( packet ) nil end

end  # class PadField

module MetaPacket::ClassMethods

  # call-seq:
  #    pad( length )
  #
  def pad( *args )
    add_field(::BitWise::PadField.new(*args))
  end
end

end  # module BitWise

# EOF
