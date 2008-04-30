# $Id$

require 'spec/spec_helper.rb'

describe BitWise::ArrayField do

  before do
    class ArrayTestPacket < ::BitWise::Packet; end
  end

  it "should read and write array fields" do
    class ArrayTestPacket < ::BitWise::Packet
      signed :x, 32
      pad 8
      array :ary, 4 do
        unsigned 16
      end
      unsigned :num, 16, :default => 4
    end

    ArrayTestPacket.code.should == 'Nx1nnnnn'
    ArrayTestPacket.length.should == 15 * 8

    p = ArrayTestPacket.new
    p.x.should == 0
    p.ary[0].should == 0
    p.ary[1].should == 0
    p.ary[2].should == 0
    p.ary[3].should == 0
    p.num.should == 4

    p.to_s.should == ("\000" * 14 + "\004")

    p.parse "beef\000\001\001\002\002\200\000\377\377\000\007"
    p.x.should == 1650812262
    p.ary[0].should == 257
    p.ary[1].should == 514
    p.ary[2].should == 32768
    p.ary[3].should == 65535
    p.num.should == 7
  end

  it "should raise an error when indices are out of range" do
    class ArrayTestPacket < ::BitWise::Packet
      array :ary, 4 do
        unsigned 16
      end
    end

    ArrayTestPacket.code.should == 'nnnn'
    ArrayTestPacket.length.should == 8 * 8

    p = ArrayTestPacket.new
    lambda{p.ary[-1]}.should raise_error(
      IndexError, "index '-1' not in range 0...4"
    )
    lambda{p.ary[4]}.should raise_error(
      IndexError, "index '4' not in range 0...4"
    )
  end

  it "should handle arrays of composite values" do
    class ArrayTestPacket < ::BitWise::Packet
      unsigned :length, 16, :default => 64
      array :sahl, 64 do
        composite do
          unsigned :lv_raw,  1
          unsigned :pc_raw, 15
        end
      end
      rest :data
    end

    ArrayTestPacket.code.should == ('n' + 'a2' * 64 + 'a*')
    ArrayTestPacket.length.should == 130 * 8

    p = ArrayTestPacket.new
    p.length.should == 64
    0.upto(63) do |ii|
      p.sahl[ii].lv_raw.should == 0
      p.sahl[ii].pc_raw.should == 0
    end
    p.data.should == ''
    p.to_s.should == ("\000@" + "\000" * 128)

    str = "\000@"
    0.upto(63) do |ii|
      p.sahl[ii].lv_raw = 1
      p.sahl[ii].pc_raw = ii + 1
      str << "\200" << (ii+1).chr
    end
    p.to_s.should == str

    str = "\377\377"
    0.upto(63) {|ii| str << "\000" << (ii+3).chr}
    str << "and this is some text to put in the data field"

    p.parse(str)
    p.length.should == 65535
    0.upto(63) do |ii|
      p.sahl[ii].lv_raw.should == 0
      p.sahl[ii].pc_raw.should == ii + 3
    end
    p.data.should == "and this is some text to put in the data field"
  end

  it "should handle arrays of arrays" do
    class ArrayTestPacket < ::BitWise::Packet
      text :name, 10 * 8
      array :matrix, 3 do
        array 3 do
          float 64
        end
      end
      unsigned :flag, 8
    end

    ArrayTestPacket.code.should == 'A10GGGGGGGGGC'
    ArrayTestPacket.length.should == 83 * 8

    p = ArrayTestPacket.new
    p.name.should == ''
    p.matrix[0][0].should == 0.0
    p.matrix[0][1].should == 0.0
    p.matrix[0][2].should == 0.0
    p.matrix[1][0].should == 0.0
    p.matrix[1][1].should == 0.0
    p.matrix[1][2].should == 0.0
    p.matrix[2][0].should == 0.0
    p.matrix[2][1].should == 0.0
    p.matrix[2][2].should == 0.0
    p.flag.should == 0
    p.to_s.should == ('          ' + "\000" * 72 + "\000")

    str = 'some text '
    str << [1, 2, 3, 4, 5, 6, 7, 8, 9].pack('G*')
    str << "\377"
    p.parse(str)

    p.name.should == 'some text'
    p.matrix[0][0].should == 1.0
    p.matrix[0][1].should == 2.0
    p.matrix[0][2].should == 3.0
    p.matrix[1][0].should == 4.0
    p.matrix[1][1].should == 5.0
    p.matrix[1][2].should == 6.0
    p.matrix[2][0].should == 7.0
    p.matrix[2][1].should == 8.0
    p.matrix[2][2].should == 9.0
    p.flag.should == 255
    p.to_s.should == str

    p.matrix[0][0] = Math::PI
    p.matrix[1][0] = 0.0
    p.matrix[2][1] = 2.13e-12
    p.matrix[1][2] = -23.1123
    
    str = 'some text '
    str << [Math::PI, 2, 3, 0, 5, -23.1123, 7, 2.13e-12, 9].pack('G*')
    str << "\377"
    p.to_s.should == str
  end

  it "should only allow a single sub-field" do
    lambda do
      BitWise::ArrayField.new(:ary, 3) do
        unsigned :a, 16
        text     :b, 10 * 8
      end
    end.should raise_error(
      BitWise::FieldError, "array fields can only contain one sub-field"
    )
  end

  it "should be byte aligned" do
    af = BitWise::ArrayField.new(:ary, 64) {signed 7}
    lambda {ArrayTestPacket.add_field(af)}.should raise_error(
      BitWise::AlignmentError,
      "array sub-field length does not fall on a byte boundary '7'"
    )

    class ArrayTestPacket < ::BitWise::Packet
      unsigned :a, 5
    end
    af = BitWise::ArrayField.new(:ary, 23) {text 10*8}
    lambda {ArrayTestPacket.add_field(af)}.should raise_error(
      ::BitWise::AlignmentError, 'array values must be byte aligned'
    )

    class ArrayTestPacket < ::BitWise::Packet
      unsigned :b, 3
         array :ary, 128 do
           signed 16, :endian => :little
         end
    end

    ArrayTestPacket.code.should == ('a1' + 'v' * 128)
    ArrayTestPacket.length.should == 257 * 8
  end

  it "should deep-copy subfields when duplicated" do
    af = BitWise::ArrayField.new(:ary, 5) {unsigned 16}
    af2 = af.dup

    af_field = af.instance_variable_get(:@field_class).fields.first
    af2_field = af2.instance_variable_get(:@field_class).fields.first
    af_field.object_id.should_not == af2_field.object_id
    af.object_id.should_not == af2.object_id

    af = BitWise::ArrayField.new(:ary, 5) {array(5) {float 64}}
    af2 = af.dup

    af_field = af.instance_variable_get(:@field_class).fields.first
    af2_field = af2.instance_variable_get(:@field_class).fields.first
    af_field.object_id.should_not == af2_field.object_id
    af.object_id.should_not == af2.object_id

    af_field = af_field.instance_variable_get(:@field_class).fields.first
    af2_field = af2_field.instance_variable_get(:@field_class).fields.first
    af_field.object_id.should_not == af2_field.object_id
  end

  it "should update length as subfields are added" do
    af = BitWise::ArrayField.new(:ary, 64)
    af.length.should == 0

    af.add_field(BitWise::SignedField.new(16))
    af.length.should == 64 * 16
  end

  it "should describe itself" do
    field = BitWise::ArrayField.new(:ary, 3, 'an array of uints') do
              unsigned 16
            end

    ary = []
    field.describe(:offset => 8) {|a| ary << a}
    ary.length.should == 4
    ary.should == [
        [nil, 'Array', 'ary', '3 ', 'an array of uints'],
        ['@1', 'Unsigned', 'ary[0]', '16b', ''],
        ['@3', 'Unsigned', 'ary[1]', '16b', ''],
        ['@5', 'Unsigned', 'ary[2]', '16b', '']
    ]

    ary = []
    field.describe {|a| ary << a}
    ary.length.should == 4
    ary.should == [
        [nil, 'Array', 'ary', '3 ', 'an array of uints'],
        ['@0', 'Unsigned', 'ary[0]', '16b', ''],
        ['@2', 'Unsigned', 'ary[1]', '16b', ''],
        ['@4', 'Unsigned', 'ary[2]', '16b', '']
    ]
  end

  after do
    Object.send :remove_const, :ArrayTestPacket
  end
end

# EOF
