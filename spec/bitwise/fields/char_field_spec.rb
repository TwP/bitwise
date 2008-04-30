# $Id$

require 'spec/spec_helper.rb'

describe BitWise::CharField do

  before do
    class CharTestPacket < ::BitWise::Packet; end
  end

  it "should read and write char fields" do
    class CharTestPacket < ::BitWise::Packet
      char :a,  10 * 8
      char :b, 128 * 8
    end

    CharTestPacket.code.should == 'a10a128'
    CharTestPacket.length.should == 138 * 8

    p = CharTestPacket.new
    p.a.should == ''
    p.b.should == ''
    p.to_s.should == "\000" * 138

    p.a = 3.14159e12
    p.b = "and this is a line of text\n"
    p.to_s.should == ("3141590000and this is a line of text\n" + ("\000" * 101))

    p.parse("1234567890this is a note from the developer" + ("\000" * 95))
    p.a.should == '1234567890'
    p.b.should == ("this is a note from the developer" + ("\000" * 95))
  end

  it "expects char values to be byte aligned" do
    uf = BitWise::CharField.new :x, 10 

    lambda {CharTestPacket.add_field(uf)}.should raise_error(
      ::BitWise::AlignmentError,
      'char values must have integer byte length'
    )

    class CharTestPacket < ::BitWise::Packet
      unsigned :a, 5
    end
    uf = BitWise::CharField.new :x, 64
    lambda {CharTestPacket.add_field(uf)}.should raise_error(
      ::BitWise::AlignmentError, 'char values must be byte aligned'
    )

    class CharTestPacket < ::BitWise::Packet
      unsigned :b, 3
          char :c, 128 * 8
    end

    CharTestPacket.code.should == 'a1a128'
    CharTestPacket.length.should == 129 * 8
  end

  after do
    Object.send :remove_const, :CharTestPacket
  end
end

# EOF
