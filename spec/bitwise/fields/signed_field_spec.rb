# $Id$

require 'spec/spec_helper.rb'

describe BitWise::SignedField do

  before do
    class SignedTestPacket < ::BitWise::Packet; end
  end

  it "should read and write 8-bit numbers natively" do
    class SignedTestPacket < ::BitWise::Packet
      signed :a, 8, :endian => :little
      signed :b, 8, :endian => :network
      signed :c, 8, :endian => :native
    end

    SignedTestPacket.code.should == 'CCC'
    SignedTestPacket.length.should == 3 * 8

    p = SignedTestPacket.new
    p.a.should == 0
    p.b.should == 0
    p.c.should == 0

    p.a = -1
    p.b = 1
    p.c = 127
    p.to_s.should == "\377\001\177"
    
    p.a = "256";  p.a.should == 0
    p.b = 255;    p.b.should == -1
    p.c = 128;    p.c.should == -128
    p.to_s.should == "\000\377\200"
  end

  it "should read and write 16-bit numbers natively" do
    class SignedTestPacket < ::BitWise::Packet
      signed :a, 16, :endian => :little
      signed :b, 16, :endian => :big
      signed :c, 16, :endian => :native
    end

    SignedTestPacket.code.should == 'vnS'
    SignedTestPacket.length.should == 6 * 8

    p = SignedTestPacket.new
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
    p.b = 65535;    p.b.should == -1
    p.c = 32768;    p.c.should == -32768
    if ENDIAN == :little
      p.to_s.should == "\000\000\377\377\000\200"
    else
      p.to_s.should == "\000\000\377\377\200\000"
    end
  end

  it "should read and write 32-bit numbers natively" do
    class SignedTestPacket < ::BitWise::Packet
      signed :a, 32, :endian => :little
      signed :b, 32, :endian => :big
      signed :c, 32, :endian => :native
    end

    SignedTestPacket.code.should == 'VNL'
    SignedTestPacket.length.should == 12 * 8

    p = SignedTestPacket.new
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
    p.b = 4294967295;    p.b.should == -1
    p.c = 2147483648;    p.c.should == -2147483648
    if ENDIAN == :little
      p.to_s.should == "\000\000\000\000\377\377\377\377\000\000\000\200"
    else
      p.to_s.should == "\000\000\000\000\377\377\377\377\200\000\000\000"
    end
  end

  it "should read and write 64-bit numbers natively" do
    class SignedTestPacket < ::BitWise::Packet
      signed :a, 64, :endian => :little
      signed :b, 64, :endian => :big
      signed :c, 64, :endian => :native
    end

    SignedTestPacket.code.should == 'a8a8Q'
    SignedTestPacket.length.should == 24 * 8

    p = SignedTestPacket.new
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
    p.b = 18446744073709551615;    p.b.should == -1
    p.c = 9223372036854775808;     p.c.should == -9223372036854775808
    if ENDIAN == :little
      p.to_s.should == "\000\000\000\000\000\000\000\000" +
                       "\377\377\377\377\377\377\377\377" +
                       "\000\000\000\000\000\000\000\200"
    else
      p.to_s.should == "\000\000\000\000\000\000\000\000" +
                       "\377\377\377\377\377\377\377\377" +
                       "\200\000\000\000\000\000\000\000"
    end
  end

  it "should read and write multi-bit values" do
    class SignedTestPacket < ::BitWise::Packet
      signed :ver,         3
      signed :type,        1
      signed :sec_flag,    1
      signed :app_id,     11
      signed :seq_flag,    2
      signed :seq_cnt,    14
      signed :length,     16
      signed :timestamp,  40
      signed :pkt_id,      8
      signed :dst_app_id,  8
      signed :pkt_dst_id,  8
    end

    SignedTestPacket.code.should == 'a2a2na5CCC'
    SignedTestPacket.length.should == 14 * 8

    p = SignedTestPacket.new
    [:ver, :type, :sec_flag, :app_id, :seq_flag, :seq_cnt, :length,
     :timestamp, :pkt_id, :dst_app_id, :pkt_dst_id].each do |field|
      p.__send__(field).should == 0
    end
    p.to_s.should == "\000" * 14

    p.ver = -1
    p.type = 0
    p.sec_flag = 1 
    p.app_id = -255
    p.seq_flag = 2
    p.seq_cnt = 1024
    p.length = 32768
    p.timestamp = 1
    p.pkt_id = 1
    p.to_s.should == "\357\001\204\000\200\000\000\000\000\000\001\001\000\000"
  end

  it "expects little-endian values to be byte aligned" do
    uf = BitWise::SignedField.new :x, 7, :endian => :little

    lambda {SignedTestPacket.add_field(uf)}.should raise_error(
      ::BitWise::AlignmentError,
      'little endian values must have integer byte length'
    )

    class SignedTestPacket < ::BitWise::Packet
      signed :a, 5
    end
    uf = BitWise::SignedField.new :x, 8, :endian => :little
    lambda {SignedTestPacket.add_field(uf)}.should raise_error(
      ::BitWise::AlignmentError, 'little endian values must be byte aligned'
    )

    class SignedTestPacket < ::BitWise::Packet
      signed :b, 3
      signed :c, 24, :endian => :little
      signed :d, 16, :endian => :little
    end

    SignedTestPacket.code.should == 'a1a3v'
    SignedTestPacket.length.should == 6 * 8
  end

  it "should not accept an unknown endian option" do
    uf = BitWise::SignedField.new :x, 7, :endian => :bad

    lambda {SignedTestPacket.add_field(uf)}.should raise_error(
      ArgumentError, "unknown endian option 'bad'"
    )
  end

  after do
    Object.send :remove_const, :SignedTestPacket
  end
end

# EOF
