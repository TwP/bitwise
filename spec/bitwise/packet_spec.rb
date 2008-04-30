# $Id$

require 'spec/spec_helper.rb'

describe BitWise::Packet do

  before do
    class TestPacket < ::BitWise::Packet
      char  :chr, 5*8, 'character data'
      array :ary, 3,   'an array of composites' do
        composite do
          pad            3
          unsigned :cnt, 5
          signed   :num, 32
        end
      end
      float :flt, 32,   'floating point data'
      text  :txt, 10*8, 'a wee bit o text'
      pad         16
      rest :payload,    'the rest of the packet'
    end
  end

  it "should not be instantiable" do
    lambda {BitWise::Packet.new}.should raise_error(NoMethodError)
  end

  it "should be inspectable" do
    p = TestPacket.new
    p.chr = '123'
    p.ary[0].cnt = 1; p.ary[0].num = -1
    p.ary[1].cnt = 2; p.ary[1].num = -2
    p.ary[2].cnt = 3; p.ary[2].num = -3
    p.flt = 1.0
    p.txt = 'hi mom'

    rgxp = Regexp.new '#<TestPacket:0x[a-fA-F0-9]+ chr="123", ary=\[\{cnt=1, num=-1\}, \{cnt=2, num=-2\}, \{cnt=3, num=-3\}\], flt=1\.0, txt="hi mom", payload="">'

    p.inspect.should match(rgxp)
  end

  it "should describe iteself" do
    TestPacket.describe.should == [
        'byte   : type       name            [ size] description',
        '----------------------------------------------------------------------',
        '@0     : Char       chr             [  40b] character data',
        '       : Array      ary             [   3 ] an array of composites',
        '       : Composite  ary[0]          [     ] ',
        '@5     : Pad                        [   3b] ',
        '@5     : Unsigned   ary[0].cnt      [   5b] ',
        '@6     : Signed     ary[0].num      [  32b] ',
        '       : Composite  ary[1]          [     ] ',
        '@10    : Pad                        [   3b] ',
        '@10    : Unsigned   ary[1].cnt      [   5b] ',
        '@11    : Signed     ary[1].num      [  32b] ',
        '       : Composite  ary[2]          [     ] ',
        '@15    : Pad                        [   3b] ',
        '@15    : Unsigned   ary[2].cnt      [   5b] ',
        '@16    : Signed     ary[2].num      [  32b] ',
        '@20    : Float      flt             [  32b] floating point data',
        '@24    : Text       txt             [  80b] a wee bit o text',
        '@34    : Pad                        [  16b] ',
        '@36    : Rest       payload         [  var] the rest of the packet'
    ]

    TestPacket.describe(:omit_header => true).should == [
        '@0     : Char       chr             [  40b] character data',
        '       : Array      ary             [   3 ] an array of composites',
        '       : Composite  ary[0]          [     ] ',
        '@5     : Pad                        [   3b] ',
        '@5     : Unsigned   ary[0].cnt      [   5b] ',
        '@6     : Signed     ary[0].num      [  32b] ',
        '       : Composite  ary[1]          [     ] ',
        '@10    : Pad                        [   3b] ',
        '@10    : Unsigned   ary[1].cnt      [   5b] ',
        '@11    : Signed     ary[1].num      [  32b] ',
        '       : Composite  ary[2]          [     ] ',
        '@15    : Pad                        [   3b] ',
        '@15    : Unsigned   ary[2].cnt      [   5b] ',
        '@16    : Signed     ary[2].num      [  32b] ',
        '@20    : Float      flt             [  32b] floating point data',
        '@24    : Text       txt             [  80b] a wee bit o text',
        '@34    : Pad                        [  16b] ',
        '@36    : Rest       payload         [  var] the rest of the packet'
    ]
  end

  it "should access fields by name" do
    p = TestPacket.new
    p.chr = '123'
    p.ary[0].cnt = 1; p.ary[0].num = -1
    p.ary[1].cnt = 2; p.ary[1].num = -2
    p.ary[2].cnt = 3; p.ary[2].num = -3
    p.flt = 1.0
    p.txt = 'hi mom'

    # test reading of data
    p['chr'].should == '123'
    p['ary[0].cnt'].should == 1
    p['ary[1].cnt'].should == 2
    p['ary[2].cnt'].should == 3
    p['ary[0].num'].should == -1
    p['ary[1].num'].should == -2
    p['ary[2].num'].should == -3
    p['flt'].should == 1.0
    p['txt'].should == 'hi mom'
    p['payload'].should == ''

    # test writing of data
    p['chr'] = "\000\123abc"
    p['ary[0].cnt'] = 10
    p['ary[1].cnt'] = 20
    p['ary[2].cnt'] = 30
    p['ary[0].num'] = -10
    p['ary[1].num'] = -20
    p['ary[2].num'] = -30
    p['flt'] = 3.14159 
    p['txt'] = 'hello'
    p['payload'] = '12345'

    p.chr.should == "\000\123abc"
    p.ary[0].cnt.should == 10 
    p.ary[1].cnt.should == 20 
    p.ary[2].cnt.should == 30 
    p.ary[0].num.should == -10
    p.ary[1].num.should == -20
    p.ary[2].num.should == -30
    p.flt.should == 3.14159
    p.txt.should == 'hello'
    p.payload.should == '12345'
  end

  it "should report its length in bits" do
    TestPacket.length.should == 288
  end

  it "should report its length in bytes" do
    TestPacket.length_in_bytes.should == 36
  end

  it "should raise an error on duplicate field names" do
    Object.send :remove_const, :TestPacket
    
    lambda do
      class TestPacket < ::BitWise::Packet
        char   :chr, 5*8
        float  :flt, 32
        text   :txt, 10*8
        pad          16
        signed :flt, 32
      end
    end.should raise_error(::BitWise::FieldError,
        "field 'flt' is already defined as a field in 'TestPacket'")

    lambda do
      class TestPacket < ::BitWise::Packet
        char :inspect, 10*8
      end
    end.should raise_error(::BitWise::FieldError,
        "field 'inspect' is already defined as a method in 'TestPacket'")
  end

  after do
    Object.send :remove_const, :TestPacket
  end
end

# EOF
