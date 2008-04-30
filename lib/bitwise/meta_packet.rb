# $Id$

module BitWise

#
#
module MetaPacket

  module ClassMethods
    attr_accessor :offset   # Current bit offset into the packet
    attr_accessor :index    # Index into the values array for the next field
    attr_accessor :fields   # Array of fields added to the packet
    alias :length :offset

    # call-seq:
    #    length_in_bytes
    #
    # Returns the length of the packet in bytes. The length is rounded up to
    # the nearest whole byte.
    #
    def length_in_bytes
      len = @offset / 8
      len += 1 unless 0 == @offset % 8
      len
    end

    # call-seq:
    #    add_field( field )
    #
    # Add the given _field_ to the list of fields contained in the packet.
    # The name of the _field_ must be unique in the packet, and it cannot
    # conflict with any methods defiend in the packet.
    #
    # The <code>add_accessors_to</code> method of the _field_ will be
    # invoked with this packet class as the argument.
    #
    def add_field( field )
      raise FieldError, 'cannot add fields to a closed packet' if closed?

      # check to see if the field name must be unique in the packet
      # if so, see if another field of the same name has been added or if
      # the field name is already defined as some other Ruby method in the
      # packet
      if field.unique?
        if @fields.find {|f| f.name == field.name}
          raise FieldError,
                "field '#{field.name}' is already defined as a field in '#{name}'"
        end

        if instance_methods.include? field.getter.to_s
          raise FieldError,
                "field '#{field.getter}' is already defined as a method in '#{name}'"
        end
      end

      # add field methods to the packet
      code, consumed = field.add_accessors_to self
      @offset += field.length
      @fields << field

      # figure out if bytes from the packet have
      # been consumed by this field
      if consumed.nil?
        bits = (@code[@c_index] || 0) + code
        @code[@c_index] = bits
        if (0 == bits % 8)
          @code[@c_index] = bits / 8
          @c_index += 1
          @index += 1
        end
      else
        @code[@c_index] = code
        @c_index += 1
        @index += consumed
      end
    end

    # call-seq:
    #    each_field {|field| block }
    #
    # Invoke the _block_ for each field in the packet.
    #
    def each_field( &block )
      @fields.each( &block )
    end

    # call-seq:
    #    default_for( field, value )
    #
    # Set the default value for the given _field_ to the _value_.
    #
    def default_for( field, value )
      f = @fields.find {|f| f.name == field}
      raise FieldError, "unknown field '#{field}'" if f.nil?
      f.default = value
    end

    # call-seq:
    #    bit_string_offset    => integer or nil
    #
    # If the current pack/unpack code is an integer then we are dealing
    # with a BitString, and this method will return the current offset into
    # that BitString. Otherwise, if the current pack/unpack code is not a
    # BitString, then +nil+ is returned.
    #
    def bit_string_offset
      return nil if closed?

      offset = @code[@index] || 0
      return nil if offset.instance_of? String
      offset
    end

    # call-seq:
    #    code   => pack/unpack string
    #
    # Returns the code string that will be used to pack/unpack the fields
    # to/from the packet data string.
    #
    def code
      return @code if closed?
      @code = @code.map {|x| x.kind_of?(Integer) ? "a#{x}" : x}.join
    end

    # call-seq:
    #    closed?    => true or false
    #
    # Returns +true+ if the packet is closed -- no more fields can be added
    # to the packet.
    #
    def closed?
      !@code.instance_of?(Array)
    end

    # call-seq:
    #    include_fields_from( packet )
    #
    # Iterate over all the fields from the _packet_ and add copies of those
    # fields to this packet.
    #
    def include_fields_from( other )
      other.fields.each {|f| add_field(f.dup)} unless other.fields.nil?
    end

    # call-seq:
    #    inherited( subclass )
    #
    # Callback invoked whenever a subclass of the class is created. This
    # method creates the internal class variables.
    #
    def inherited( other )
      {:@offset      => 0,
       :@index       => 0,
       :@c_index     => 0,
       :@code        => [],
       :@fields      => []
      }.each {|name,value| other.instance_variable_set(name, value)}
    end
  end

  # call-seq:
  #    MetaPacket.included( other )
  #
  # This callback is invoked whenever the MetaPacket module is included in
  # another module or class. It is used to add class methods to the _other_
  # class so that the _other_ can be used in BitWise packets.
  #
  def self.included( other )
    if Class === other
      other.extend ClassMethods 
      undef_instance_methods_in other,
          :except => %w(__send__ __id__ class inspect)
    end
    super
  end

  # call-seq:
  #    MetaPacket.undef_instance_methods_in( other, :except => [] )
  #
  # Undefines all instance methods in the _other_ class with the exception
  # of those methods listed in the <code>:except</code> array.
  #
  def self.undef_instance_methods_in( other, opts = {} )
    exceptions = opts[:except] || []
    other.instance_methods.each do |m|
      other.class_eval {undef_method(m) unless exceptions.include? m}
    end
  end

end  # module MetaPacket
end  # module BitWise

# EOF
