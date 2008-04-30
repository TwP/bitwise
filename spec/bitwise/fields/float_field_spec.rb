# $Id$

require 'spec/spec_helper.rb'

describe BitWise::FloatField do

  before do
    class FloatTestPacket < ::BitWise::Packet; end
  end

  it "should read and write 32-bit numbers natively" do
    class FloatTestPacket < ::BitWise::Packet
      float :a, 32, :endian => :little
      float :b, 32, :endian => :network
      float :c, 32, :endian => :native
    end

    FloatTestPacket.code.should == 'egf'
    FloatTestPacket.length.should == 12 * 8

    p = FloatTestPacket.new
    p.a.should == 0.0
    p.b.should == 0.0
    p.c.should == 0.0

    p.a = 3.14159e123
    p.b = 1
    p.c = -8.42212e-23
    if ENDIAN == :little
      p.to_s.should == "\000\000\200\177?\200\000\000f\242\313\232"
    else
      p.to_s.should == "\000\000\200\177?\200\000\000\232\313\242f"
    end
  end

  it "should read and write 64-bit numbers natively" do
    class FloatTestPacket < ::BitWise::Packet
      float :a, 64, :endian => :little
      float :b, 64, :endian => :big
      float :c, 64, :endian => :native
    end

    FloatTestPacket.code.should == 'EGD'
    FloatTestPacket.length.should == 24 * 8

    p = FloatTestPacket.new
    p.a.should == 0.0
    p.b.should == 0.0
    p.c.should == 0.0

    p.a = 3.14159e123
    p.b = 1
    p.c = -8.42212e-23
    if ENDIAN == :little
      p.to_s.should == "\203!\336;p\002\223Y" +
                       "?\360\000\000\000\000\000\000" + 
                       "$\202\355\272LtY\273"
    else
      p.to_s.should == "\203!\336;p\002\223Y" +
                       "?\360\000\000\000\000\000\000" + 
                       "\273YtL\272\355\202$"
    end
  end

  it "expects float values to be byte aligned" do
    uf = BitWise::FloatField.new :x, 16

    lambda {FloatTestPacket.add_field(uf)}.should raise_error(
      ::BitWise::AlignmentError,
      "float values must be 32 or 64 bits in length '16'"
    )

    class FloatTestPacket < ::BitWise::Packet
      unsigned :a, 5
    end
    uf = BitWise::FloatField.new :x, 64
    lambda {FloatTestPacket.add_field(uf)}.should raise_error(
      ::BitWise::AlignmentError, 'float values must be byte aligned'
    )

    class FloatTestPacket < ::BitWise::Packet
      unsigned :b, 3
         float :c, 32, :endian => :little
         float :d, 64, :endian => :native
    end

    FloatTestPacket.code.should == 'a1eD'
    FloatTestPacket.length.should == 13 * 8
  end

  it "should not accept an unknown endian option" do
    uf = BitWise::FloatField.new :x, 64, :endian => :bad

    lambda {FloatTestPacket.add_field(uf)}.should raise_error(
      ArgumentError, "unknown endian option 'bad'"
    )
  end

  after do
    Object.send :remove_const, :FloatTestPacket
  end
end

# EOF
