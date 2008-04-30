# $Id$

require 'bitwise/packet'

module BitWise

class ArrayField < Field

  # A subclass of the ArrayClass is used to manage the sub-fields of the
  # ArrayField. An instance of the ArrayClass subclass is created to
  # handle access to the composite sub-fields themselves.
  #
  # The ArrayClass is similar to a BitWise Packet, but more restrictive
  # in that it is tailored for use by the ArrayField.
  #
  class ArrayClass
    include ::BitWise::MetaPacket

    # call-seq:
    #    ArrayClass.add_field( field )
    #
    # Add the given _field_ to this array class. Only one field can be added
    # to the array class; further calls to this method will raise a
    # FieldError. The field does not need a name.
    #
    def self.add_field( field )
      unless @fields.empty?
        raise FieldError, "array fields can only contain one sub-field"
      end

      field.instance_variable_set :@name, :_array_value
      super
      class_eval {private :_array_value, :_array_value=}
    end

    # call-seq:
    #    ArrayClass.new( values, offset, array_length )
    #
    # Creates a new ArrayClass using the given _values_ array from the
    # containing Packet and the initial _offset_ into the values array where
    # array fields can be found. The _array_length_ is also required in
    # order to idnex to the next array element.
    #
    def initialize( values, offset, ary_length )
      @_values = ::BitWise::ArrayShim.new(values)
      @_values.offset = offset
      @_offset = offset
      @_array_length = ary_length
    end

    # call-seq:
    #    ary[index]    => object
    #
    # Returns the object located at the given _index_ of the array object.
    # Raises an IndexError if the _index_ is negative or grater than or
    # equal to the array length.
    #
    def []( index )
      _check index
      @_values.offset = @_offset + (index * self.class.index)
      _array_value
    end

    # call-seq:
    #    ary[index] = object
    #
    # Set the _object_ at the given _index_ in the array object.
    # Raises an IndexError if the _index_ is negative or grater than or
    # equal to the array length.
    #
    def []=( index, value )
      _check index
      @_values.offset = @_offset + (index * self.class.index)
      self._array_value = value
    end

    # call-seq:
    #    inspect    => string
    #
    # Returns a string containing a human-readable representation of the
    # array object.
    #
    def inspect
      vals = []
      (0...@_array_length).each {|ii| vals << self[ii].inspect}
      "[#{vals.join(', ')}]"
    end


    private

    # call-seq:
    #    check( index )    => self
    #
    # Raises an IndexError if the given index is not in the range of this
    # array object.
    #
    def _check( index )
      if index < 0 || index >= @_array_length
        raise IndexError,
              "index '#{index}' not in range 0...#@_array_length"
      end
      self
    end
  end  # class ArrayClass

  attr_reader :array_length   # The number of elements in the array field

  # call-seq:
  #    ArrayField.new( name, array_length ) { block }
  #
  def initialize( *args, &block )
    super(*args)
    @array_length = @length

    @field_class = Class.new(ArrayClass)
    @field_class.class_eval(&block) if block_given?
  end

  # call-seq:
  #    dup    => array field
  #
  # Creates a duplicate of this array field. A deep copy of the
  # underlying array class is made along with the sub-fields of that
  # class.
  #
  def dup
    other = super
    other.instance_variable_set :@field_class, Class.new(ArrayClass)
    @field_class.fields.each {|field| other.add_field(field.dup)}
    other
  end

  # call-seq:
  #    add_field( field )
  #
  # Add a sub-field to the this array field. A FieldError is raised if
  # the underlying array class is closed or has already had a sub-field
  # added to it.
  #
  def add_field( field )
    @field_class.add_field( field )
    self
  end

  # call-seq:
  #    length    => integer
  #
  # Returns the length in bits of this array field.
  #
  def length
    @array_length * @field_class.length
  end

  # call-seq:
  #    describe( :offset => nil ) {|ary| block}
  #
  # Yields to the given _block_ an array of five values that servers to
  # describe this field. If an offset is given, then it is used to determine
  # the byte offset of this field in a packet.
  #
  # Each sub-field in the array is then yielded to the _block_. If the array
  # has five elements, then the _block_ will be called six times -- once for
  # the array and then five times for each array element.
  #
  # When the array field descriptor is yielded to the block, the _bit_size_
  # is the number of elements in the array and not the size of the field in
  # bits.
  #
  def describe( opts = {} )
    opts[:offset] ||= 0
    len = "%d " % @array_length
    yield [nil, self.class.field_name, @name.to_s, len, @description]

    f = @field_class.fields.first
    (0...@array_length).each do |num|
      f.describe(opts) do |ary|
        ary[2].sub!('_array_value', "#{@name}[#{num}]") unless ary[2].nil?
        yield ary
      end
    end
  end

  #
  #
  def add_accessors_to( packet )

    # if the underlying array class is not closed, then close it
    # now and verify that the length is an integer number of bytes
    unless @field_class.closed?
      @field_class.code
      @length *= @field_class.length

      unless 0 == @field_class.length % 8
        raise AlignmentError, "array sub-field length does not fall on a " +
                              "byte boundary '#{@field_class.length}'"
      end
    end

    # go about the business of adding setter/getter methods
    # to the given packet
    #
    getter = self.getter
    setter = self.setter
    field_class = @field_class

    offset = packet.offset
    index = packet.index

    unless 0 == offset % 8
      raise AlignmentError, 'array values must be byte aligned'
    end

    meta = class << packet; self end
    meta.class_eval {define_method("class_for_#{getter}") {field_class}}

    packet.class_eval <<-CODE
      def #{getter}
        @#{name} ||= self.class.class_for_#{getter}.new(
                         @_values, #{index}, #@array_length)
      end

      private
      def #{setter}( val )
        @#{name} ||= self.class.class_for_#{getter}.new(
                        @_values, #{index}, #@array_length)
        
        f = @#{name}.class.fields.first
        (0...#@array_length).each {|i| @#{name}[i] = f.default}
      end
    CODE

    [@field_class.code * @array_length, @field_class.index * @array_length]
  end

end  # class ArrayField

module MetaPacket::ClassMethods

  # call-seq:
  #    array( name, array_length ) { block }
  #
  #
  def array( *args, &block )
    add_field(::BitWise::ArrayField.new(*args, &block))
  end

end  # module MetaPacket
end  # module BitWise

# EOF
