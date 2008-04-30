# $Id$

require 'spec/spec_helper.rb'

describe BitWise::RestField do

  before do
    class RestTestPacket < ::BitWise::Packet; end
  end

  it "should read and write to the 'rest' of the packet" do
    class RestTestPacket < ::BitWise::Packet
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
      rest     :payload
    end

    RestTestPacket.code.should == 'a2a2na5CCCa*'
    RestTestPacket.length.should == 14 * 8

    p = RestTestPacket.new
    [:ver, :type, :sec_flag, :app_id, :seq_flag, :seq_cnt, :length,
     :timestamp, :pkt_id, :dst_app_id, :pkt_dst_id].each do |field|
      p.__send__(field).should == 0
    end
    p.payload.should == ''
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

    p.payload = 'this is a message from the developer'
    p.to_s.should == "8*\204\000\200\000\000\000\000\000\001\001\000\000" +
                     "this is a message from the developer"

    p.payload = nil
    p.to_s.should == "8*\204\000\200\000\000\000\000\000\001\001\000\000"
  end

  it "should be byte aligned" do
    class RestTestPacket < ::BitWise::Packet
      unsigned :a, 15
    end

    lambda {RestTestPacket.rest(:payload)}.should raise_error(
      ::BitWise::AlignmentError
    )

    class RestTestPacket < ::BitWise::Packet
      unsigned :b,  1
      rest     :payload
    end

    RestTestPacket.code.should == 'a2a*'
    RestTestPacket.length.should == 2 * 8
  end

  it "should only be added once" do
    class RestTestPacket < ::BitWise::Packet
      unsigned :a, 16
      rest     :payload
    end

    lambda {RestTestPacket.rest(:payload)}.should raise_error(
      ::BitWise::FieldError, "rest field already defined as 'payload'"
    )
  end

  it "should describe itself" do
    f = BitWise::RestField.new(:payload, 8, 'the rest of the story')

    ary = f.describe {|a| a}
    ary.should == [nil, 'Rest', 'payload', 'var', 'the rest of the story']

    opts = {:offset => 128}
    ary = f.describe(opts) {|a| a}
    ary.should == ['@16', 'Rest', 'payload', 'var', 'the rest of the story']
    opts[:offset].should == 128
  end

  after do
    Object.send :remove_const, :RestTestPacket
  end
end

# EOF
