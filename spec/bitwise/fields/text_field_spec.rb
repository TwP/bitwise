# $Id$

require 'spec/spec_helper.rb'

describe BitWise::TextField do

  before do
    class TextTestPacket < ::BitWise::Packet; end
  end

  it "should read and write text fields" do
    class TextTestPacket < ::BitWise::Packet
      text :a,  10 * 8
      text :b, 128 * 8
    end

    TextTestPacket.code.should == 'A10A128'
    TextTestPacket.length.should == 138 * 8

    p = TextTestPacket.new
    p.a.should == ''
    p.b.should == ''
    p.to_s.should == ' ' * 138

    p.a = 3.14159e12
    p.b = "and this is a line of text\n"
    p.to_s.should == "3141590000and this is a line of text\n                                                                                                     "

    p.parse("1234567890this is a note from the developer" + ("\000" * 95))
    p.a.should == '1234567890'
    p.b.should == 'this is a note from the developer'

    p.parse("1234567890this is a note from the developer\n" + (' ' * 94))
    p.a.should == '1234567890'
    p.b.should == "this is a note from the developer\n"
  end

  it "expects text values to be byte aligned" do
    uf = BitWise::TextField.new :x, 10 

    lambda {TextTestPacket.add_field(uf)}.should raise_error(
      ::BitWise::AlignmentError,
      'text values must have integer byte length'
    )

    class TextTestPacket < ::BitWise::Packet
      unsigned :a, 5
    end
    uf = BitWise::TextField.new :x, 64
    lambda {TextTestPacket.add_field(uf)}.should raise_error(
      ::BitWise::AlignmentError, 'text values must be byte aligned'
    )

    class TextTestPacket < ::BitWise::Packet
      unsigned :b, 3
          text :c, 128 * 8
    end

    TextTestPacket.code.should == 'a1A128'
    TextTestPacket.length.should == 129 * 8
  end

  after do
    Object.send :remove_const, :TextTestPacket
  end
end

# EOF
