# $Id$

require 'bitwise/packet'

module BitWise

#
#
class CompositeField < Field

  # A subclass of the CompositeClass is used to manage the sub-fields of the
  # CompositeField. An instance of the CompositeClass subclass is created to
  # handle access to the composite sub-fields themselves.
  #
  # The CompositeClass is similar to a BitWise Packet, but more restrictive
  # in that it is tailored for use by the CompositeField.
  #
  class CompositeClass
    include ::BitWise::MetaPacket

    # call-seq:
    #    CompositeClass.new( values, offset )
    #
    # Creates a new CompositeClass using the given _values_ array from the
    # containing Packet and the initial _offset_ into the values array where
    # composite fields can be found.
    #
    def initialize( values, offset )
      @_values = ::BitWise::ArrayShim.new(values)
      @_values.offset += offset
    end

    # call-seq:
    #    inspect    => string
    #
    # Returns a string containing a human-readable representation of the
    # composite object.
    #
    def inspect
      ary = []
      self.class.each_field {|f| ary << f.inspect_in(self)}
      ary.compact!
      "{#{ary.join(INSPECT_OPTS[:separator])}}"
    end
  end  # class CompositeClass

  # call-seq:
  #    CompositeField.new( name, description = '', opts = {} )
  #    CompositeField.new( name, description = '', opts = {} ) { block }
  #
  def initialize( *args, &block )
    super(*args)

    @field_class = Class.new(CompositeClass)
    @field_class.class_eval(&block) if block_given?
  end

  # call-seq:
  #    dup    => composite field
  #
  # Creates a duplicate of this composite field. A deep copy of the
  # underlying composite class is made along with the sub-fields of that
  # class.
  #
  def dup
    other = super
    other.instance_variable_set :@field_class, Class.new(CompositeClass)
    @field_class.fields.each {|field| other.add_field(field.dup)}
    other
  end

  # call-seq:
  #    add_field( field )
  #
  # Add a sub-field to the this composite field. A FieldError is raised if
  # the underlying composite class is closed.
  #
  def add_field( field )
    @field_class.add_field( field )
    self
  end

  # call-seq:
  #    length    => integer
  #
  # Returns the length in bits of this composite field.
  #
  def length
    @field_class.length
  end

  # call-seq:
  #    describe( :offset => nil ) {|ary| block}
  #
  # Yields to the given _block_ an array of five values that servers to
  # describe this field. If an offset is given, then it is used to determine
  # the byte offset of this field in a packet.
  #
  # Each sub-field in the composite is then yielded to the _block_. If the
  # composite has four elements, then the _block_ will be called five times
  # -- once for the composite and then four times for composite elements.
  #
  def describe( opts = {} )
    opts[:offset] ||= 0
    yield [nil, self.class.field_name, @name.to_s, nil, @description]

    @field_class.each_field do |f|
      f.describe(opts) do |ary|
        ary[2] = "#{@name}.#{ary[2]}" unless ary[2].nil?
        yield ary
      end
    end
  end

  # call-seq:
  #    add_accessors_to( packet )
  #
  #
  def add_accessors_to( packet )

    # if the underlying composite class is not closed, then close it
    # now and verify that the length is an integer number of bytes
    unless @field_class.closed?
      @field_class.code
      @length = @field_class.length

      unless 0 == @field_class.length % 8
        raise AlignmentError, "composite field length does not fall on a " +
                              "byte boundary '#{@field_class.length}'"
      end
    end

    # go about the business of adding setter/getter methods
    # to the given packet

    getter = self.getter
    setter = self.setter
    field_class = @field_class

    offset = packet.offset
    index = packet.index

    unless 0 == offset % 8
      raise AlignmentError, 'composite fields must be byte aligned'
    end

    meta = class << packet; self end
    meta.class_eval {define_method("class_for_#{getter}") {field_class}}

    packet.class_eval <<-CODE
      def #{getter}
        @#{name} ||= self.class.class_for_#{getter}.new(@_values, #{index})
      end

      private
      def #{setter}( val )
        @#{name} ||= self.class.class_for_#{getter}.new(@_values, #{index})
        @#{name}.class.fields.each {|f| @#{name}.__send__(f.setter, f.default)}
      end
    CODE

    [@field_class.code, @field_class.index]
  end
end  # class CompositeField


module MetaPacket::ClassMethods

  # call-seq:
  #    composite( name, description = nil, opts = {} ) { block }
  #
  #
  def composite( *args, &block )
    add_field(::BitWise::CompositeField.new(*args, &block))
  end

end  # module MetaPacket
end  # module BitWise

# EOF
