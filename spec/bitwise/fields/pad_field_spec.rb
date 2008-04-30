# $Id$

require 'spec/spec_helper.rb'

describe BitWise::PadField do

  before do
    class PadTestPacket < ::BitWise::Packet; end
  end

  it "should add padding to a packet" do
    class PadTestPacket < ::BitWise::Packet
           pad      5
      unsigned :a,  3
           pad     16
        signed :b, 16
    end

    PadTestPacket.code.should == 'a1x2n'
    PadTestPacket.length.should == 5 * 8

    p = PadTestPacket.new
    p.to_s.should == "\000" * 5

    p.a = 7
    p.b = 2**16 - 1
    p.to_s.should == "\007\000\000\377\377"
  end

  it "should not create public setter/getter methods" do
    class PadTestPacket < ::BitWise::Packet
      unsigned :a,  3
           pad      5
        signed :b, 16
    end

    PadTestPacket.code.should == 'a1n'
    PadTestPacket.length.should == 3 * 8

    p = PadTestPacket.new

    lambda {p.pad}.should raise_error(NoMethodError)
    lambda {p.pad = nil}.should raise_error(NoMethodError)
  end

  it "should describe itself" do
    f = BitWise::PadField.new(8, 'some padding')

    ary = f.describe {|a| a}
    ary.should == [nil, 'Pad', nil, '8b', 'some padding']

    ary = f.describe(:offset => 31) {|a| a}
    ary.should == ['@3', 'Pad', nil, '8b', 'some padding']
  end

  after do
    Object.send :remove_const, :PadTestPacket
  end
end

# EOF
