
require 'bitwise/meta_packet'

module BitWise

#
#
class Packet
  include ::BitWise::MetaPacket

  class << self
    private :new
    attr_accessor :rest_field

    # call-seq:
    #    code    => pack/unpack string
    #
    # Returns the code string that will be used to pack/unpack the fields
    # to/from the packet data string.
    #
    def code
      return @code if closed?
      super

      unless 0 == length % 8
        raise AlignmentError, "packet length does not fall on a " +
                              "byte boundary '#{self.class.length}'"
      end

      @code << 'a*' unless @rest_field.nil?
      @code
    end

    # call-seq:
    #    inherited( subclass )
    #
    # Callback invoked whenever a subclass of the Packet class is created.
    # This method creates the internal class variables and it adds all the
    # fields of this packet to the subclass.
    #
    def inherited( other )
      super
      MetaPacket.undef_instance_methods_in other,
          :except => %w(__send__ __id__ class inspect parse to_s [] []=)
      other.instance_variable_set :@rest_field, nil
      other.include_fields_from self
      class << other; public :new end
    end

    # call-seq:
    #    Packet.describe_fields    => array
    #
    # Iterates over all the fields in the packet and returns an array of
    # field descriptions. Each fields description is itself an array
    # containing the following elements:
    #
    #    [byte_offset, type, name, bit_size, description]
    #
    #    byte_offset  => byte offset in the packet where the field resides
    #    type         => type of field (SignedField, UnsignedField, etc.)
    #    name         => name of the field
    #    bit_size     => size of the field in bits
    #    description  => verbose field description
    #
    # All elemetns are strings. The name of the field can be used to get
    # that field value from the packet.
    #
    def describe_fields( &block )
      opts = {:offset => 0}

      if block_given?
        each_field {|f| f.describe(opts, &block)}
        @rest_field.describe(opts, &block)
        return nil 
      end

      result = []
      each_field {|f| f.describe(opts) {|a| result << a}}
      @rest_field.describe(opts) {|a| result << a} if @rest_field
      result
    end

    # call-seq:
    #    Packet.describe    => array
    #
    # Iterates over all he fields in the packet and returns an array of
    # formatted strings describing the fields. Most often this array will be
    # printed to the screen.
    #
    #    puts Packet.describe
    #
    def describe( opts = {} )
      result = []

      unless opts[:omit_header]
        result << DESCRIBE_FORMAT % ["byte", "type", "name", "size", "description"]
        result << "-"*70
      end
      result.concat describe_fields.map! {|a| DESCRIBE_FORMAT % a}
      result
    end
  end  # class << self


  # call-seq:
  #    Packet.new( str = nil )
  #
  def initialize( str = nil )
    @_code = self.class.code
    @_values = []

    @_fields = self.class.fields

    rf = self.class.rest_field

    if str.nil?
      @_fields.each {|f| self.__send__(f.setter, f.default)}
      unless rf.nil?
        @_values << nil
        self.__send__(rf.setter, rf.default) 
      end
    else
      self.parse str
    end

    yield self if block_given?
  end

  # call-seq:
  #    parse( string )    => packet
  #
  def parse( str )
    raise ArgumentError, 'expecting a String' unless str.instance_of? String
    @_values.replace(str.unpack(@_code))
    self
  end

  # call-seq:
  #    to_s    => binary string
  #
  def to_s
    @_values.pack @_code
  end

  # call-seq:
  #    inspect    => string
  #
  # Returns a string containing a human-readable representation of the
  # packet.
  #
  def inspect
    ary = []
    self.class.each_field {|f| ary << f.inspect_in(self)}

    rf = self.class.rest_field
    ary << rf.inspect_in(self) unless rf.nil?
    ary.compact!

    str = super.split(' ').first
    str << " #{ary.join(INSPECT_OPTS[:separator])}>"

    str
  end

  # call-seq:
  #    pkt[ name ]
  #
  # Returns the value of the field identified by _name_. The _name_ is the
  # fully qualified name of the field returned in the +describe_fields+
  # method of the packet class.
  #
  def []( name )
    eval "self.#{name}"
  end

  # call-seq:
  #    pkt[ name ] = value
  #
  # Set the field identifed by _name_ to the given _value_. The _name_ is
  # the fully qualified name of the field returned in the +describe_fields+
  # method of the packet class.
  #    
  def []=( name, val )
    eval "self.#{name} = #{val.inspect}"
  end

  # TODO
  # these methods should be modified to use the field introspection
  # mechanisms for building up the array and hash

  # call-seq:
  #
#  def to_a
#    ary = @_fields.inject(Array.new) do |a,f|
#            a << [f.name, self.__send__(f.getter)]
#            a
#          end
#    ary << [@_rest.name, self.__send__(@_rest.getter)] unless @_rest.nil?
#    ary
#  end
# 
#  # call-seq:
#  #
#  def to_h
#    hsh = @_fields.inject(Hash.new) do |h,f|
#            h[f.name] = self.__send__(f.getter)
#            h
#          end
#    hsh[@_rest.name] = self.__send__(@_rest.getter) unless @_rest.nil?
#    hsh
#  end


end  # class Packet
end  # module BitWise

# EOF
