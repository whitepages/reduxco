require 'spec_helper'

describe Reduxco::Context::CallableTable do

  let(:identity_dynref) { Reduxco::CallableRef.new(:identity) }
  let(:identity_callable) { ->(c){c} }
  let(:app_callable) { ->(c){c[:identity]} }

  it 'should instantiate with an array of maps' do
    table = Reduxco::Context::CallableTable.new( [{:identity => identity_callable}, {:app => app_callable}] )
    table.should include(identity_dynref)
    table.resolve(identity_dynref).should_not be_nil
  end

  it 'should instantiate with an array of arrays of arrays' do
    table = Reduxco::Context::CallableTable.new( [[[:identity, identity_callable]], [[:app, app_callable]]] )
    table.should include(identity_dynref)
    table.resolve(identity_dynref).should_not be_nil
  end

  describe 'introspection' do

    let(:example_callable) { ->(c){c} }

    before(:each) do
      map1 = {:moho => example_callable, :eve => example_callable}
      map2 = {:eve => example_callable, :kerbin => example_callable}
      @table = Reduxco::Context::CallableTable.new([map1,map2])
    end

    it 'should introspect existence of static refs' do
      @table.should include(Reduxco::CallableRef.new(:moho,1))
      @table.should include(Reduxco::CallableRef.new(:eve,1))
      @table.should include(Reduxco::CallableRef.new(:eve,2))
      @table.should include(Reduxco::CallableRef.new(:kerbin,2))
    end

    it 'should introspect existence of dynamic refs' do
      @table.should include(Reduxco::CallableRef.new(:moho))
      @table.should include(Reduxco::CallableRef.new(:eve))
      @table.should include(Reduxco::CallableRef.new(:kerbin))
    end

    it 'should introspect the non-existance of static refs' do
      @table.should_not include(Reduxco::CallableRef.new(:duna,1))
      @table.should_not include(Reduxco::CallableRef.new(:moho,2))
    end

    it 'should introspect the non-existance of dynamic refs' do
      @table.should_not include(Reduxco::CallableRef.new(:duna))
    end

  end

  describe 'resolution' do

    before(:each) do
      @map1 = {moho: ->(c){1}, eve: ->(c){2}, jool: ->(c){5}}
      @map2 = {eve: ->(c){'second'}, kerbin: ->(c){3}}
      @map3 = {jool: ->(c){'5th'}}
      @table = Reduxco::Context::CallableTable.new([@map1,@map2,@map3])
    end

    let(:context) {double('context')}

    it 'should resolve top level static ref' do
      @table.resolve(Reduxco::CallableRef.new(:moho,1)).tap do |callref, callable|
        callref.should == Reduxco::CallableRef.new(:moho,1)
        callable.call(context).should == 1
      end
    end

    it 'should resolve a deeper level static ref' do
      @table.resolve(Reduxco::CallableRef.new(:kerbin,2)).tap do |callref, callable|
        callref.should == Reduxco::CallableRef.new(:kerbin,2)
        callable.call(context).should == 3
      end
    end

    it 'should resolve a static ref that shadows higher level one' do
      @table.resolve(Reduxco::CallableRef.new(:eve,2)).tap do |callref, callable|
        callref.should == Reduxco::CallableRef.new(:eve,2)
        callable.call(context).should == 'second'
      end
    end

    it 'should resolve a shadowed static ref' do
      @table.resolve(Reduxco::CallableRef.new(:eve,1)).tap do |callref, callable|
        callref.should == Reduxco::CallableRef.new(:eve,1)
        callable.call(context).should == 2
      end
    end

    it 'should resolve simple (non-shadowed) dynamic refs to correct level' do
      @table.resolve(Reduxco::CallableRef.new(:moho)).tap do |callref, callable|
        callref.should == Reduxco::CallableRef.new(:moho,1)
        callable.call(context).should == 1
      end

      @table.resolve(Reduxco::CallableRef.new(:kerbin)).tap do |callref, callable|
        callref.should == Reduxco::CallableRef.new(:kerbin,2)
        callable.call(context).should == 3
      end
    end

    it 'should resolve a shadowed dynamic ref to the lowest level' do
      @table.resolve(Reduxco::CallableRef.new(:eve)).tap do |callref, callable|
        callref.should == Reduxco::CallableRef.new(:eve,2)
        callable.call(context).should == 'second'
      end
    end


    it 'should return a callable value of nil if a static ref cannot be resolved' do
      @table.resolve(Reduxco::CallableRef.new(:eeloo, 1)).tap do |callref, callable|
        callref.should be_nil
        callable.should be_nil
      end
    end

    it 'should return a callable value of nil if a dynamic ref cannot be resolved' do
      @table.resolve(Reduxco::CallableRef.new(:eeloo)).tap do |callref, callable|
        callref.should be_nil
        callable.should be_nil
      end
    end

    it 'should use :[] as an alias to :resolve' do
      @table.method(:[]).should == @table.method(:resolve)
    end

    describe 'super' do

      it 'should resolve super for a static ref' do
        @table.resolve_super(Reduxco::CallableRef.new(:eve,2)).tap do |callref, callable|
          callref.should == Reduxco::CallableRef.new(:eve,1)
          callable.call(context).should == 2
        end
      end

      it 'should resolve super across depth gaps' do
        @table.resolve_super(Reduxco::CallableRef.new(:jool,3)).tap do |callref, callable|
          callref.should == Reduxco::CallableRef.new(:jool, 1)
          callable.call(context).should == 5
        end
      end

      it 'should return a callable value of nil if a super ref cannot be resolved' do
        @table.resolve_super(Reduxco::CallableRef.new(:kerbin,2)).tap do |callref, callable|
          callref.should be_nil
          callable.should be_nil
        end
      end

      it 'should raise an exception with a dynamic ref' do
        ->{ @table.resolve_super(Reduxco::CallableRef.new(:moho)) }.should raise_error(ArgumentError)
      end

    end

  end

end
