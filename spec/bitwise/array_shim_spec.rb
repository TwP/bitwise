# $Id$

require 'spec/spec_helper.rb'

describe BitWise::ArrayShim do

  it 'should have zero offset when created' do
    shim = BitWise::ArrayShim.new
    shim.offset.should == 0
  end

  it 'should apply an offset when setting elements' do
    ary = []
    shim = BitWise::ArrayShim.new ary
    shim.offset = 2

    shim[0] = 1
    shim[1] = 2

    ary[0].should == nil
    ary[1].should == nil
    ary[2].should == 1
    ary[3].should == 2
  end

  it 'should apply an offset when getting elements' do
    ary = (1..10).to_a
    shim = BitWise::ArrayShim.new ary
    shim.offset = 3

    shim[0].should == 4
    shim[1].should == 5
    shim[6].should == 10
    shim[7].should == nil

    shim.at(2).should == 6
    shim.at(3).should == 7
  end

end

# EOF
