# $Id$

require 'spec/spec_helper.rb'

describe BitWise::UnsignedField do

  before do
    class UnsignedTestPacket < ::BitWise::Packet; end
  end

  it "should read and write 8-bit numbers natively" do
    class UnsignedTestPacket < ::BitWise::Packet
      unsigned :a, 8, :endian => :little
      unsigned :b, 8, :endian => :network
      unsigned :c, 8, :endian => :native
    end

    UnsignedTestPacket.code.should == 'CCC'
    UnsignedTestPacket.length.should == 3 * 8

    p = UnsignedTestPacket.new
    p.a.should == 0
    p.b.should == 0
    p.c.should == 0

    p.a = 255
    p.b = 1
    p.c = 128
    p.to_s.should == "\377\001\200"
    
    p.a = "256";  p.a.should == 0
    p.b = -1;     p.b.should == 255
    p.c = 1025;   p.c.should == 1
    p.to_s.should == "\000\377\001"
  end

  it "should read and write 16-bit numbers natively" do
    class UnsignedTestPacket < ::BitWise::Packet
      unsigned :a, 16, :endian => :little
      unsigned :b, 16, :endian => :big
      unsigned :c, 16, :endian => :native
    end

    UnsignedTestPacket.code.should == 'vnS'
    UnsignedTestPacket.length.should == 6 * 8

    p = UnsignedTestPacket.new
    p.a.should == 0
    p.b.should == 0
    p.c.should == 0

    p.a = 255
    p.b = 1
    p.c = 128
    if ENDIAN == :little
      p.to_s.should == "\377\000\000\001\200\000"
    else
      p.to_s.should == "\377\000\000\001\000\200"
    end
    
    p.a = "65536";  p.a.should == 0
    p.b = -1;       p.b.should == 65535
    p.c = 1025;     p.c.should == 1025
    if ENDIAN == :little
      p.to_s.should == "\000\000\377\377\001\004"
    else
      p.to_s.should == "\000\000\377\377\004\001"
    end
  end

  it "should read and write 32-bit numbers natively" do
    class UnsignedTestPacket < ::BitWise::Packet
      unsigned :a, 32, :endian => :little
      unsigned :b, 32, :endian => :big
      unsigned :c, 32, :endian => :native
    end

    UnsignedTestPacket.code.should == 'VNL'
    UnsignedTestPacket.length.should == 12 * 8

    p = UnsignedTestPacket.new
    p.a.should == 0
    p.b.should == 0
    p.c.should == 0

    p.a = 255
    p.b = 1
    p.c = 128
    if ENDIAN == :little
      p.to_s.should == "\377\000\000\000\000\000\000\001\200\000\000\000"
    else
      p.to_s.should == "\377\000\000\000\000\000\000\001\000\000\000\200"
    end
    
    p.a = "4294967296";  p.a.should == 0
    p.b = -1;            p.b.should == 4294967295
    p.c = 1025;          p.c.should == 1025
    if ENDIAN == :little
      p.to_s.should == "\000\000\000\000\377\377\377\377\001\004\000\000"
    else
      p.to_s.should == "\000\000\000\000\377\377\377\377\000\000\004\001"
    end
  end

  it "should read and write 64-bit numbers natively" do
    class UnsignedTestPacket < ::BitWise::Packet
      unsigned :a, 64, :endian => :little
      unsigned :b, 64, :endian => :big
      unsigned :c, 64, :endian => :native
    end

    UnsignedTestPacket.code.should == 'a8a8Q'
    UnsignedTestPacket.length.should == 24 * 8

    p = UnsignedTestPacket.new
    p.a.should == 0
    p.b.should == 0
    p.c.should == 0

    p.a = 4294967297
    p.b = 1
    p.c = 128
    if ENDIAN == :little
      p.to_s.should == "\001\000\000\000\001\000\000\000" +
                       "\000\000\000\000\000\000\000\001" +
                       "\200\000\000\000\000\000\000\000"
    else
      p.to_s.should == "\001\000\000\000\001\000\000\000" +
                       "\000\000\000\000\000\000\000\001" +
                       "\000\000\000\000\000\000\000\200"
    end
    
    p.a = "18446744073709551616";  p.a.should == 0
    p.b = -1;                      p.b.should == 18446744073709551615
    p.c = 1025;                    p.c.should == 1025
    if ENDIAN == :little
      p.to_s.should == "\000\000\000\000\000\000\000\000" +
                       "\377\377\377\377\377\377\377\377" +
                       "\001\004\000\000\000\000\000\000"
    else
      p.to_s.should == "\000\000\000\000\000\000\000\000" +
                       "\377\377\377\377\377\377\377\377" +
                       "\000\000\000\000\000\000\004\001"
    end
  end

  it "should read and write multi-bit values" do
    class UnsignedTestPacket < ::BitWise::Packet
      unsigned :ver,         3
      unsigned :type,        1
      unsigned :sec_flag,    1
      unsigned :app_id,     11
      unsigned :seq_flag,    2
      unsigned :seq_cnt,    14
      unsigned :length,     16
      unsigned :timestamp,  40
      unsigned :pkt_id,      8
      unsigned :dst_app_id,  8
      unsigned :pkt_dst_id,  8
    end

    UnsignedTestPacket.code.should == 'a2a2na5CCC'
    UnsignedTestPacket.length.should == 14 * 8

    p = UnsignedTestPacket.new
    [:ver, :type, :sec_flag, :app_id, :seq_flag, :seq_cnt, :length,
     :timestamp, :pkt_id, :dst_app_id, :pkt_dst_id].each do |field|
      p.__send__(field).should == 0
    end
    p.to_s.should == "\000" * 14

    p.ver = 1
    p.type = 1
    p.sec_flag = 1 
    p.app_id = 42
    p.seq_flag = 2
    p.seq_cnt = 1024
    p.length = 32768
    p.timestamp = 1
    p.pkt_id = 1
    p.to_s.should == "8*\204\000\200\000\000\000\000\000\001\001\000\000"
  end

  it "expects little-endian values to be byte aligned" do
    uf = BitWise::UnsignedField.new :x, 7, :endian => :little

    lambda {UnsignedTestPacket.add_field(uf)}.should raise_error(
      ::BitWise::AlignmentError,
      'little endian values must have integer byte length'
    )

    class UnsignedTestPacket < ::BitWise::Packet
      unsigned :a, 5
    end
    uf = BitWise::UnsignedField.new :x, 8, :endian => :little
    lambda {UnsignedTestPacket.add_field(uf)}.should raise_error(
      ::BitWise::AlignmentError, 'little endian values must be byte aligned'
    )

    class UnsignedTestPacket < ::BitWise::Packet
      unsigned :b, 3
      unsigned :c, 24, :endian => :little
      unsigned :d, 16, :endian => :little
    end

    UnsignedTestPacket.code.should == 'a1a3v'
    UnsignedTestPacket.length.should == 6 * 8
  end

  it "should not accept an unknown endian option" do
    uf = BitWise::UnsignedField.new :x, 7, :endian => :bad

    lambda {UnsignedTestPacket.add_field(uf)}.should raise_error(
      ArgumentError, "unknown endian option 'bad'"
    )
  end

  after do
    Object.send :remove_const, :UnsignedTestPacket
  end
end

# EOF
