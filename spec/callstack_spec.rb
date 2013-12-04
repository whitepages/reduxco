require 'spec_helper'

describe Reduxco::Context::Callstack do

  before(:each) do
    @stack = Reduxco::Context::Callstack.new([:top, :middle, :bottom])
  end

  it 'should return the depth' do
    @stack.depth.should == 3
  end

  it 'should get the top frame' do
    @stack.top.should == :top
  end

  it 'should initialize as empty' do
    stack = Reduxco::Context::Callstack.new
    stack.depth.should == 0
  end

  it 'should be able to initialize with an array, top elem first' do
    @stack.depth.should == 3
    @stack.top.should == :top
  end

  it 'should allow peeking into the stack' do
    @stack.peek(0).should == @stack.top
    @stack.peek(@stack.depth).should be_nil
    @stack.peek(1).should == :middle
    @stack.peek(2).should == :bottom
  end

  it 'should pop' do
    frame = @stack.pop

    @stack.depth.should == 2
    frame.should == :top
  end

  it 'should push' do
    s = @stack.push(:new_top)

    @stack.depth.should == 4
    @stack.top.should == :new_top

    s.object_id.should == @stack.object_id
  end

  it 'should check for frame inclusion' do
    @stack.should include(:middle)

    @stack.should_not include(:eeloo)
  end

  it 'should return the rest of the stack' do
    rest = @stack.rest

    rest.depth.should == 2
    rest.top.should == :middle

    rest.should be_kind_of(@stack.class)
  end

  it 'should return a properly structured copy of the stack' do
    dup = @stack.dup

    dup.should be_kind_of(@stack.class)
    dup.object_id.should_not == @stack.object_id

    dup.top.should == @stack.top
  end

  it 'should not mutate the copy of the stack out from under it' do
    dup = @stack.dup

    @stack.push(:moho)
    dup.should_not include(:moho)

    dup.push(:eve)
    @stack.should_not include(:eve)
  end

  describe 'conversion and formatting' do

    let(:frame) do
      double('frame').tap do |f|
        f.stub(:to_s) {'frame-string'}
        f.stub(:inspect) {'frame-inspect'}
      end
    end

    it 'should output to_s with the top element first' do
      str = @stack.to_s

      str.index('top').should < str.index('bottom')
    end

    it 'should inspect with the top element first' do
      str = @stack.inspect
      str.index('top').should < str.index('bottom')
    end

    it 'should invoke inspect of frames when inspecting' do
      @stack.push(frame)

      frame.should_receive(:inspect)
      str = @stack.inspect

      str.should include('frame-inspect')
    end

    it 'should convert to a caller-style callstack' do
      cs = @stack.to_caller

      cs.each {|tr| tr.should be_kind_of(String)}
      cs.first.should include('top')
      cs.last.should include('bottom')
    end

    it 'should prepend a callstack line into the caller-style callstack, conterting it to string' do
      top = Object.new
      cs = @stack.to_caller(top)

      cs.each {|tr| tr.should be_kind_of(String)}

      head, *tail = cs

      head.should == top.to_s
      tail.should == @stack.to_caller
    end

  end

end
