# $Id$

require 'spec/spec_helper.rb'

describe BitWise::Field do

  before do
    @klass = ::BitWise::Field
  end

  it "should generate setter/getter method names" do
    lambda {@klass.getter(nil)}.should raise_error(NoMethodError)

    @klass.setter(nil).should  == :'='

    @klass.getter(:tom).should == :tom
    @klass.setter(:tom).should == :tom=

    name = 'some_long_name'
    @klass.getter(name).should == :some_long_name
    @klass.setter(name).should == :some_long_name=
    name.should == 'some_long_name'
  end

  it "should accept constructor arguments in any order" do
    field = @klass.new
    field.name.should == nil
    field.length.should == nil
    field.description.should == ''
    field.default.should == nil
    field.setter.should == :'='
    lambda{field.getter}.should raise_error(NoMethodError)
  
    field = @klass.new(:temp)
    field.name.should == :temp
    field.length.should == nil
    field.description.should == ''
    field.default.should == nil
    field.setter.should == :temp=
    field.getter.should == :temp

    field = @klass.new('string')
    field.name.should == :string
    field.length.should == nil
    field.description.should == ''
    field.default.should == nil
    field.setter.should == :string=
    field.getter.should == :string

    field = @klass.new('field', 24)
    field.name.should == :field
    field.length.should == 24
    field.description.should == ''
    field.default.should == nil
    field.setter.should == :field=
    field.getter.should == :field

    field = @klass.new(:blah, 15, 'just a field with the blahs')
    field.name.should == :blah
    field.length.should == 15
    field.description.should == 'just a field with the blahs'
    field.default.should == nil
    field.setter.should == :blah=
    field.getter.should == :blah

    field = @klass.new('paint a happy little field', :happy, 7)
    field.name.should == :happy
    field.length.should == 7
    field.description.should == 'paint a happy little field'
    field.default.should == nil
    field.setter.should == :happy=
    field.getter.should == :happy

    field = @klass.new(:defaults, 10, :default => 100)
    field.name.should == :defaults
    field.length.should == 10
    field.description.should == ''
    field.default.should == 100
    field.setter.should == :defaults=
    field.getter.should == :defaults

    field = @klass.new(80, 'name', :default => 'tim pease')
    field.name.should == :name
    field.length.should == 80
    field.description.should == ''
    field.default.should == 'tim pease'
    field.setter.should == :name=
    field.getter.should == :name
  end

  it "should raise an error for unexpected constructor arguments" do
    lambda{@klass.new('name', ['bad arg'], 80)}.should raise_error(
      ArgumentError, "unexpected argument type 'Array'"
    )
    lambda{@klass.new('name', 80, Object)}.should raise_error(
      ArgumentError, "unexpected argument type 'Class'"
    )
  end

  it "should accept a default value" do
    field = @klass.new(:name, 10)
    field.default.should == nil

    field.default = 100
    field.default.should == 100

    field.default = "and now it's a string"
    field.default.should == "and now it's a string"
  end

  it "should allow the description to be modified" do
    field = @klass.new(:name, 10)
    field.description.should == ''

    field.description = 'this is a description of the name field'
    field.description.should == 'this is a description of the name field'
  end

  it "should make a deep copy of the options when duplicated" do
    field1 = @klass.new(:name, 10, "this is the description", :default => 'default')
    field2 = field1.dup

    field1.object_id.should_not == field2.object_id
    field1.name.object_id.should == field2.name.object_id
    field1.length.object_id.should == field2.length.object_id

    field2.description << ' and more'
    field2.description.should == 'this is the description and more'
    field1.description.should == 'this is the description'

    field2.default = 'new default'
    field2.default.should == 'new default'
    field1.default.should == 'default'
  end

  it "should not allow lengths of zero bits or less" do
    lambda{@klass.new(:name, 0)}.should raise_error(ArgumentError)
    lambda{@klass.new(:name, -1)}.should raise_error(ArgumentError)
  end

  it "should not be able to add accessor methods to packets" do
    field = @klass.new(:name, 10)
    lambda{field.add_accessors_to(nil)}.should raise_error(NotImplementedError)
  end

  it "should describe itself" do
    field = @klass.new(:name, 16, 'this is the description')

    ary = field.describe {|a| a}
    ary.should == [nil, 'Field', 'name', '16b', 'this is the description']

    opts = {:offset => 22}
    ary = field.describe(opts) {|a| a}
    ary.should == ['@2', 'Field', 'name', '16b', 'this is the description']
    opts[:offset].should == 38
  end

  after do
    @klass = nil
  end
end
