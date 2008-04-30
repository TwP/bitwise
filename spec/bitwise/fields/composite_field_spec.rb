# $Id$

require 'spec/spec_helper.rb'

describe BitWise::CompositeField do

  before do
    class CompositeTestPacket < ::BitWise::Packet; end
  end

  it "should read and write composite fields" do
    class CompositeTestPacket < ::BitWise::Packet
      signed :x, 32
      pad 8
      composite :cmp do
        signed :num, 16
        float :flt, 32, :endian => :little
        unsigned :a, 5
        unsigned :b, 3
      end
      unsigned :num, 16, :default => 4
    end

    CompositeTestPacket.code.should == 'Nx1nea1n'
    CompositeTestPacket.length.should == 14 * 8

    p = CompositeTestPacket.new
    p.x.should == 0
    p.cmp.num.should == 0
    p.cmp.flt.should == 0.0
    p.cmp.a.should == 0
    p.cmp.b.should == 0
    p.num.should == 4

    p.to_s.should == ("\000" * 13 + "\004")

    p.parse "beef\000\001\001\002\002\200\000\377\377\000"
    p.x.should == 1650812262
    p.cmp.num.should == 257
    p.cmp.flt.should == "\002\002\200\000".unpack('e').first
    p.cmp.a.should == 31
    p.cmp.b.should == 7
    p.num.should == 65280
  end

  it "should handle an array as a composite sub-field" do
    class CompositeTestPacket < ::BitWise::Packet
      unsigned :length, 16, :default => 64
      composite :cmp do
        array(:ary, 3) {unsigned 8}
        unsigned :num, 32
      end
      rest :data
    end

    CompositeTestPacket.code.should == 'nCCCNa*'
    CompositeTestPacket.length.should == 9 * 8

    p = CompositeTestPacket.new
    p.length.should == 64
    p.cmp.ary[0].should == 0
    p.cmp.ary[1].should == 0
    p.cmp.ary[2].should == 0
    p.cmp.num.should == 0
    p.data.should == ''
    p.to_s.should == ("\000@" + "\000" * 7)

    p.cmp.ary[0] = 1
    p.cmp.ary[1] = 2
    p.cmp.ary[2] = 3
    p.cmp.num = 1023
    p.to_s.should == "\000@\001\002\003\000\000\003\377"

    str = "\377\377\300\200\100\001\002\003\004"
    str << "and this is some text to put in the data field"

    p.parse(str)
    p.length.should == 65535
    p.cmp.ary[0].should == 192
    p.cmp.ary[1].should == 128
    p.cmp.ary[2].should == 64
    p.cmp.num.should == 16909060
    p.data.should == "and this is some text to put in the data field"
  end

  it "should handle nested composite fields" do
    class CompositeTestPacket < ::BitWise::Packet
      text :name, 10 * 8
      composite :cmp1 do
        composite :cmp2 do
          unsigned :num, 16
          signed :chr, 8
        end
        signed :chr, 8
      end
      unsigned :flag, 8
    end

    CompositeTestPacket.code.should == 'A10nCCC'
    CompositeTestPacket.length.should == 15 * 8

    p = CompositeTestPacket.new
    p.name.should == ''
    p.cmp1.cmp2.num.should == 0
    p.cmp1.cmp2.chr.should == 0
    p.cmp1.chr.should == 0
    p.flag.should == 0
    p.to_s.should == "          \000\000\000\000\000"

    p.name = 'some text'
    p.cmp1.chr = 128
    p.cmp1.cmp2.chr = 64
    p.flag = 255
    p.to_s.should == "some text \000\000@\200\377"

    str = "abc123def4\377\377TwP"

    p.parse(str)
    p.name.should == 'abc123def4'
    p.cmp1.cmp2.num.should == 65535
    p.cmp1.cmp2.chr.should == ?T
    p.cmp1.chr.should == ?w
    p.flag.should == ?P
    p.to_s.should == str
  end

  it "should be byte aligned" do
    cf = BitWise::CompositeField.new(:cmp) {signed :num, 7}
    lambda {CompositeTestPacket.add_field(cf)}.should raise_error(
      BitWise::AlignmentError,
      "composite field length does not fall on a byte boundary '7'"
    )

    class CompositeTestPacket < ::BitWise::Packet
      unsigned :a, 5
    end
    cf = BitWise::CompositeField.new(:cmp) {text :txt, 10*8}
    lambda {CompositeTestPacket.add_field(cf)}.should raise_error(
      ::BitWise::AlignmentError, 'composite fields must be byte aligned'
    )

    class CompositeTestPacket < ::BitWise::Packet
      unsigned :b, 3
      composite :cmp do
        array :ary, 128 do
           signed 16, :endian => :little
        end
      end
    end

    CompositeTestPacket.code.should == ('a1' + 'v' * 128)
    CompositeTestPacket.length.should == 257 * 8
  end

  it "should deep-copy subfields when duplicated" do
    cf = BitWise::CompositeField.new(:cmp) do
           signed :num, 16, 'a signed number'
           unsigned :len, 8, 'an unsigned number'
           text :txt, 218 * 8, 'some text'
           float :flt, 64, 'floating point value'
         end
    cf2 = cf.dup

    cf_fields = cf.instance_variable_get(:@field_class).fields
    cf2_fields = cf2.instance_variable_get(:@field_class).fields
    fields = cf_fields.zip(cf2_fields)

    fields.each do |orig,copy|
      orig.object_id.should_not == copy.object_id
    end
    cf.object_id.should_not == cf2.object_id

    cf = BitWise::CompositeField.new(:cmp) do
           signed :num, 16, 'a signed number'
           composite :cmp2, 'a nested composite field' do
             unsigned :len, 8, 'an unsigned number'
             text :txt, 218 * 8, 'some text'
             float :flt, 64, 'floating point value'
           end
         end
    cf2 = cf.dup

    cf_fields = cf.instance_variable_get(:@field_class).fields
    cf2_fields = cf2.instance_variable_get(:@field_class).fields
    fields = cf_fields.zip(cf2_fields)

    fields.each do |orig,copy|
      orig.object_id.should_not == copy.object_id
    end
    cf.object_id.should_not == cf2.object_id
  end

  it "should update length as subfields are added" do
    cf = BitWise::CompositeField.new(:cmp)
    cf.length.should == 0

    cf.add_field(BitWise::UnsignedField.new(:num, 16))
    cf.length.should == 16

    cf.add_field(BitWise::CharField.new(:text, 128 * 8))
    cf.length.should == 16 + 128 * 8
  end

  it "should describe itself" do
    cf = BitWise::CompositeField.new(:cmp) do
           signed :num, 16, 'a signed number'
           unsigned :len, 8, 'an unsigned number'
           pad 8
           text :txt, 218 * 8, 'some text'
           float :flt, 64, 'floating point value'
         end

    ary = []
    cf.describe(:offset => 16) {|a| ary << a}
    ary.length.should == 6
    ary.should == [
      [nil, 'Composite', 'cmp', nil, ''],
      ['@2', 'Signed', 'cmp.num', '16b', 'a signed number'],
      ['@4', 'Unsigned', 'cmp.len', '8b', 'an unsigned number'],
      ['@5', 'Pad', nil, '8b', ''],
      ['@6', 'Text', 'cmp.txt', '1744b', 'some text'],
      ['@224', 'Float', 'cmp.flt', '64b', 'floating point value']
    ]

    ary = []
    cf.describe {|a| ary << a}
    ary.length.should == 6
    ary.should == [
      [nil, 'Composite', 'cmp', nil, ''],
      ['@0', 'Signed', 'cmp.num', '16b', 'a signed number'],
      ['@2', 'Unsigned', 'cmp.len', '8b', 'an unsigned number'],
      ['@3', 'Pad', nil, '8b', ''],
      ['@4', 'Text', 'cmp.txt', '1744b', 'some text'],
      ['@222', 'Float', 'cmp.flt', '64b', 'floating point value']
    ]
  end

  after do
    Object.send :remove_const, :CompositeTestPacket
  end
end

# EOF
