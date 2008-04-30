# $Id$

module BitWise

# An +ArrayShim+ is used to access an underlying +Array+ object with a fixed
# offset. The result is that element N in the shim is actually element
# (N + offset) in the underlying array.
#
class ArrayShim

  # call-seq:
  #    ArrayShim.new( array = [] )
  #
  # Creates a new +ArrayShim+ backed by the given _array_.
  #
  def initialize( ary = [] )
    @ary = ary
    @offset = 0
  end

  # Offset to apply to array indicies when setting and getting values.
  attr_accessor :offset

  # call-seq:
  #    shim[index]   => value
  #
  # Returns the _value_ at the given _index_. The array shim applies it's
  # offset to the _index_ before retrieving the value.
  #
  def []( index )
    @ary.at(index + @offset)
  end

  # call-seq:
  #    shim[index] = value
  #
  # Sets the _value_ at the given _index_. The array shim applies it's
  # offset to the _index_ before setting the _value_.
  #
  def []=( index, value )
    @ary[index + @offset] = value
  end

  # call-seq:
  #    at( index )    => value
  #
  def at( index )
    @ary.at(index + @offset)
  end

end  # class ArrayShim
end  # module BitWise

# EOF
