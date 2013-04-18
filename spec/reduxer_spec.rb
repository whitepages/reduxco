require 'spec_helper'

describe Reduxco::Reduxer do

  describe 'reduce' do

    it 'should alias call to reduce' do
      reduxer = Reduxco::Reduxer.new
      reduxer.method(:call).should == reduxer.method(:reduce)
    end

    it 'should alias [] to reduce' do
      reduxer = Reduxco::Reduxer.new
      reduxer.method(:[]).should == reduxer.method(:reduce)
    end

    it 'should delegate reduce to its context call method' do
      reduxer = Reduxco::Reduxer.new

      refname = double('refname')
      reduxer.context.should_receive(:call).with(refname)

      reduxer.reduce(refname)
    end

  end

  describe 'initialize' do

    it 'should initialize with callable maps' do
      map1 = double('map1').tap {|m| m.stub(:each)}
      map2 = double('map2').tap {|m| m.stub(:each)}

      Reduxco::Context.should_receive(:new).with(map1, map2)

      reduxer = Reduxco::Reduxer.new(map1, map2)
    end

    it 'should initialize with a copy of a Context when it is the first argument' do
      context = Reduxco::Context.new
      context.should_receive(:dup)

      reduxer = Reduxco::Reduxer.new(context)
      reduxer.context.should_not == context
    end

  end

  describe 'dup' do

    it 'should create a new Reduxer with a new Context' do
      reduxer = Reduxco::Reduxer.new

      Reduxco::Context.should_receive(:new)
      dup = reduxer.dup

      dup.context.should_not == reduxer.context
    end

    it 'should dup with the same callable maps.' do
      map1 = double('map1').tap {|m| m.stub(:each)}
      map2 = double('map2').tap {|m| m.stub(:each)}

      reduxer = Reduxco::Reduxer.new(map1, map2)

      Reduxco::Context.should_receive(:new).with(map1, map2)

      dup = reduxer.dup
    end

    it 'should dup as the same type' do
      reduxer = Reduxco::Reduxer.new
      dup = reduxer.dup
      dup.should be_kind_of(reduxer.class)
    end

  end

  describe 'general' do

    it 'should provide access to the wrapped context' do
      reduxer = Reduxco::Reduxer.new
      reduxer.context.should == reduxer.instance_variable_get(:@context)
    end

  end

end
