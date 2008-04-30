# $Id$

require 'spec/spec_helper.rb'

describe BitWise::BitString, " when reading bit fields" do

  before do
    @bs = ::BitWise::BitString
    @str = '11'
  end

  it "should return single-bit numbers" do
    @bs[@str, 0].should == 0
    @bs[@str, 2].should == 1
    @bs[@str, 6].should == 0
    @bs[@str, 7].should == 1

    @bs[@str, 8].should == 0
  end

  it "should return multi-bit numbers" do
    @bs[@str, 0,2].should == 0
    @bs[@str, 0,3].should == 1
    @bs[@str, 0,4].should == 3
    @bs[@str, 0,8].should == 49

    @bs[@str, 2,2].should == '11'.to_i(2)
    @bs[@str, 2,6].should == '110001'.to_i(2)
    @bs[@str, 3,5].should == '10001'.to_i(2)
  end

  it "should span byte boundaries" do
    @bs[@str, 0,16].should == '0011000100110001'.to_i(2)
    @bs[@str, 2,12].should == '110001001100'.to_i(2)
    @bs[@str, 2,10].should == '1100010011'.to_i(2)
    @bs[@str, 5,6].should  == '001001'.to_i(2)
    @bs[@str, 7,3].should  == '100'.to_i(2)

    @str = [1,2,4,8,16,32,64,128].pack('C*')
    @bs[@str, 0...40].should == 4328785936
    @bs[@str, 7...40].should == 4328785936
    @bs[@str, 7...36].should == 270549121
  end

  it "should accept ranges" do
    @bs[@str, 0..15].should == '0011000100110001'.to_i(2)
    @bs[@str, 0...16].should == '0011000100110001'.to_i(2)
    @bs[@str, 7..9].should  == '100'.to_i(2)
    @bs[@str, 7...10].should  == '100'.to_i(2)
  end

  it "should handle little-endian values" do
    @str = [1,2,4,8,16,32,64,128].pack('C*')
    @bs[@str, 0...40, :little].should == 68853957121
    @bs[@str, 8, 40, :little].should == 137707914242
    @bs[@str, 48...56, :little].should == 64
    @bs[@str, 48, 16, :little].should == 32832

    lambda {@bs[@str, 1...8, :little]}.should raise_error(ArgumentError)
    lambda {@bs[@str, 0..8, :little]}.should raise_error(ArgumentError)
  end

  it "should raise an ArgumentError for wrong arguments" do
    lambda {@bs[@str, /123/]}.should raise_error(ArgumentError)
    lambda {@bs[@str, '123']}.should raise_error(ArgumentError)
    lambda {@bs[@str, 1,'123']}.should raise_error(ArgumentError)
  end

  it "should raise an ArgumentError when not enough bits are in the string" do
    lambda {@bs[@str, 0,17]}.should raise_error(ArgumentError)
  end

  it "should raise a RangeError when the offset is negative" do
    lambda {@bs[@str, -1]}.should raise_error(RangeError)
    lambda {@bs[@str, -10,20]}.should raise_error(RangeError)
    lambda {@bs[@str, -2..8]}.should raise_error(RangeError)
  end

  it "should raise a RangeError unless the length is greater than zero" do
    lambda {@bs[@str, 0,-1]}.should raise_error(RangeError)
    lambda {@bs[@str, 5..-1]}.should raise_error(RangeError)
    lambda {@bs[@str, 7..2]}.should raise_error(RangeError)
    lambda {@bs[@str, 5...5]}.should raise_error(RangeError)
  end

  after do
    @bs = nil
    @str = nil
  end
end


describe BitWise::BitString, " when writing bit fields" do

  before do
    @bs = ::BitWise::BitString
    @str = ''
  end

  it "should grow the string to hold data" do
    @str.length.should == 0

    @bs[@str, 0,8] = 255;  @str.length.should == 1
    @bs[@str, 8]   = 1;    @str.length.should == 2
    @bs[@str, 15]  = 1;    @str.length.should == 2
    @bs[@str, 38]  = 1;    @str.length.should == 5
  end

  it "should store single-bit values" do
    @bs[@str, 7] = 1;  @bs[@str, 0,8].should == 1
    @bs[@str, 5] = 1;  @bs[@str, 0,8].should == 5
    @bs[@str, 1] = 1;  @bs[@str, 0,8].should == 69
    @bs[@str, 0] = 1;  @bs[@str, 0,8].should == 197
    @bs[@str, 2] = 1;  @bs[@str, 0,8].should == 229
    @bs[@str, 5] = 0;  @bs[@str, 0,8].should == 225
    @bs[@str, 1] = 0;  @bs[@str, 0,8].should == 161

    @bs[@str, 15] = 1;  @bs[@str, 8,8].should == 1
    @bs[@str, 13] = 1;  @bs[@str, 8,8].should == 5
    @bs[@str,  9] = 1;  @bs[@str, 8,8].should == 69
    @bs[@str,  8] = 1;  @bs[@str, 8,8].should == 197
    @bs[@str, 10] = 1;  @bs[@str, 8,8].should == 229
    @bs[@str, 13] = 0;  @bs[@str, 8,8].should == 225
    @bs[@str,  9] = 0;  @bs[@str, 8,8].should == 161

    @bs[@str, 31] = 1;  @bs[@str, 24,8].should == 1
    @bs[@str, 29] = 1;  @bs[@str, 24,8].should == 5
    @bs[@str, 25] = 1;  @bs[@str, 24,8].should == 69
    @bs[@str, 24] = 1;  @bs[@str, 24,8].should == 197
    @bs[@str, 26] = 1;  @bs[@str, 24,8].should == 229
    @bs[@str, 29] = 0;  @bs[@str, 24,8].should == 225
    @bs[@str, 25] = 0;  @bs[@str, 24,8].should == 161
  end 

  it "should store multi-bit values" do
    @bs[@str, 5..7] = 5;    @bs[@str, 0,8].should == 5
    @bs[@str, 0..7] = 123;  @bs[@str, 0,8].should == 123
    @bs[@str, 0..7] = 0;    @bs[@str, 0,8].should == 0
    @bs[@str, 1..4] = 15;   @bs[@str, 0,8].should == 120

    @bs[@str, 19..23] = 17;  @bs[@str, 16,8].should == 17

    @bs[@str, 0,24].should == 7864337
  end

  it "should span byte boundaries" do
    @bs[@str, 7..8] = 3
    @bs[@str, 0,16].should == 384

    @bs[@str, 1] = 1;
    @bs[@str, 15] = 1;
    @bs[@str, 5..12] = 255
    @bs[@str, 0,16].should == 18425

    @bs[@str, 14..39] = 0xFFFFFFFF
    @bs[@str, 0,40].should == 309170536447
  end

  it "should truncate values when storing" do
    @bs[@str, 7] = 3;  @bs[@str, 0,8].should == 1
    @bs[@str, 5] = 3;  @bs[@str, 0,8].should == 5
    @bs[@str, 1] = 3;  @bs[@str, 0,8].should == 69
    @bs[@str, 0] = 3;  @bs[@str, 0,8].should == 197
    @bs[@str, 2] = 3;  @bs[@str, 0,8].should == 229
    @bs[@str, 5] = 2;  @bs[@str, 0,8].should == 225
    @bs[@str, 1] = 2;  @bs[@str, 0,8].should == 161

    @bs[@str, 13..15] = 15;  @bs[@str, 8,8].should == 7
    @bs[@str, 8..9]   = 15;  @bs[@str, 8,8].should == 199
    @bs[@str, 10..12] =  3;  @bs[@str, 8,8].should == 223
    @bs[@str, 13..15] =  8;  @bs[@str, 8,8].should == 216

    @bs[@str, 0..39] = 0
    @bs[@str, 14..39] = 0xFFFFFFFF
    @bs[@str, 0,40].should == 67108863
  end

  it "should accept ranges" do
    @bs[@str, 0..15] = 0x37FF;   @bs[@str, 0,16].should == 0x37FF
    @bs[@str, 0...16] = 0x1000;  @bs[@str, 0,16].should == 0x1000
    @bs[@str, 7..9] = 42;        @bs[@str, 0,16].should == 4224
    @bs[@str, 7...10] = 5;       @bs[@str, 0,16].should == 4416
  end

  it "should accept negative values" do
    @bs[@str, 0..3] = -1;  @bs[@str, 0,8].should == 0xF0
    @bs[@str, 8..11] = -1; @bs[@str, 0,16].should == 0xF0F0
  end

  it "should handle little-endian values" do
    str = [1,2,4,8,16,32,64,128].pack('C*')

    @bs[@str, 0...40, :little] = 68853957121;   @str.should == str[0..4]
    @bs[@str, 8...48, :little] = 137707914242;  @str.should == str[0..5]
    @bs[@str, 48, 8,  :little] = 64;            @str.should == str[0..6]
    @bs[@str, 48, 16, :little] = 32832;         @str.should == str[0..7]

    lambda {@bs[@str, 1...8, :little] = 0}.should raise_error(ArgumentError)
    lambda {@bs[@str, 0..8, :little] = 0}.should raise_error(ArgumentError)
  end

  it "should raise a ArgumentError for non-integer values" do
    lambda {@bs[@str, 4] = 'blah'}.should raise_error(ArgumentError)
    lambda {@bs[@str, 4] = [1]}.should raise_error(TypeError)
  end

  it "should raise a RangeError when the offset is negative" do
    lambda {@bs[@str, -1] = 1}.should raise_error(RangeError)
    lambda {@bs[@str, -10,20] = 1}.should raise_error(RangeError)
    lambda {@bs[@str, -2..8] = 1}.should raise_error(RangeError)
  end

  it "should raise a RangeError unless the length is greater than zero" do
    lambda {@bs[@str, 0,-1] = 1}.should raise_error(RangeError)
    lambda {@bs[@str, 5..-1] = 1}.should raise_error(RangeError)
    lambda {@bs[@str, 7..2] = 1}.should raise_error(RangeError)
    lambda {@bs[@str, 5...5] = 1}.should raise_error(RangeError)
  end

  after do
    @bs = nil
    @str = nil
  end
end
