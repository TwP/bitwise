# $Id$

module BitWise

#
#
class Field

  class << self
    # call-seq:
    #    Field.getter( name )
    #
    # Returns the getter method name (as a Symbol) constructed from the
    # given field _name_.
    #
    def getter( name ) name.to_sym end

    # call-seq:
    #    Field.setter( name )
    #
    # Returns the setter method name (as a Symbol) constructed from the
    # given field _name_.
    #
    def setter( name ) (name.to_s + '=').to_sym end

    # call-seq:
    #    Field.field_name
    #
    # Returns the field name for this Field. This is a more display friendly
    # version of the class name, and it is used in the <code>describe</code>
    # method.
    #
    def field_name
      @field_name ||= begin
        %r/(\w+)Field$/.match(name)[1]
      rescue
        %r/(\w+)$/.match(name)[1]
      end
    end
  end

  # call-seq:
  #    Field.new( name, length, description = nil, opts = {} )
  #
  # Creates a new field that can be added to any object that can contain
  # fields (packets, composite fields, and array fields). The _name_ is the
  # name of the field. _length_ is the length of the field in bits. The
  # _description_ is used when inspecting packets -- it used as a longer
  # documentation for the field.
  #
  # Allowable options:
  #
  #    :default    => the default value for this field
  #    :unique     => field name must be unique in the packet
  #
  # The field _name_ must be unique within the packet this field will be
  # added to. It is used to create the setter and getter methods for
  # accessing the data within the packet. However, if the
  # <code>:unique</code> option is set to false, this requirement will not
  # be enforced.
  #
  def initialize( *args )
    @opts = (args.last.instance_of?(Hash) ? args.pop : {})
    @name, @length, @description = nil

    args.each do |a|
      case a
      when Symbol; @name, @description = a, @name.to_s
      when Integer; @length = a
      when String
        if @name.nil? then @name = a.to_sym
        else @description = a end
      else
        raise ArgumentError, "unexpected argument type '#{a.class.name}'"
      end
    end

    unless @length.nil? or @length > 0
      raise ArgumentError, "length must be greater than zero '#{@length}'"
    end

    @description = @description.to_s

    self.default = @opts[:default]
    @opts[:unique] = true unless @opts.has_key? :unique
  end

  attr_reader :name    # Name of the field
  attr_reader :length  # Length of field in bits
  alias :size :length

  attr_accessor :description  # Description of the field

  # call-seq:
  #    dup    => new field
  #
  # Creates a duplicate of this field. A deep copy of the underlying options
  # array and description is made.
  #
  def dup
    other = super
    [:@opts, :@description].each do |var|
      d = instance_variable_get(var).dup
      other.instance_variable_set(var, d)
    end
    other
  end

  # call-seq:
  #    setter
  #
  # The name of the setter method for this field. This method will be added
  # to packets when the <code>add_accessors_to</code> method is called.
  #
  def setter
    @setter ||= Field.setter(@name)
  end

  # call-seq:
  #    getter
  #
  # The name of the getter method for this field. This method will be added
  # to packets when the <code>add_accessors_to</code> method is called.
  #
  def getter
    @getter ||= Field.getter(@name)
  end

  # call-seq:
  #    default
  #
  # Returns the default value for this field.
  #
  def default
    @opts[:default]
  end

  # call-seq:
  #    default = val
  #
  # Sets the default value for this field.
  #
  def default=( val )
    @opts[:default] = val
  end

  # call-seq:
  #    unique?
  #
  # Returns <code>true</code> if the field name must be unique within the
  # packet; <code>false</code> if the field name does not need to be unique
  # (as in the case of the pad field).
  #
  def unique?
    @opts[:unique]
  end

  # call-seq:
  #    inspect_in( packet )
  #
  def inspect_in( packet )
    v = packet.__send__(getter)
    sprintf(INSPECT_OPTS[:field_format], @name, v.inspect)
  end

  # call-seq:
  #    describe( :offset => nil ) {|ary| block}
  #
  # Yields to the given _block_ an array of five values that serves to
  # describe this field. If an offset is given, then it is used to determine
  # the byte offset of this field in a packet.
  #
  #    [byte_offset, type, name, bit_size, description]
  #
  #    byte_offset  => byte offset in the packet where the field resides
  #    type         => type of field (SignedField, UnsignedField, etc.)
  #    name         => name of the field
  #    bit_size     => size of the field in bits
  #    description  => verbose field description
  #
  # All elements in the array are strings. The _byte_offset_ and the _name_
  # can be +nil+.
  #
  def describe( opts = {} )
    byte_offset = nil
    if opts.has_key? :offset
      byte_offset = '@%d' % (opts[:offset] / 8)
      opts[:offset] += @length
    else
      opts[:offset] = @length
    end
    len = "%db" % @length
    
    yield [byte_offset, self.class.field_name, @name.to_s, len, @description]
  end

  # call-seq:
  #    add_accessors_to( packet )
  #
  # This method will add a <code>setter</code> and <code>getter</code>
  # method to the given _packet_. Therefore, _packet_ is expected to be a
  # class.
  #
  def add_accessors_to( packet )
    raise NotImplementedError
  end

end  # class Field
end  # module BitWise

# EOF
