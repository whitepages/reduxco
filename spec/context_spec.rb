require 'spec_helper'

describe Reduxco::Context do

  let(:add_map) do
    {
      sum: ->(c){ c[:a]+c[:b] },
      a: ->(c){3},
      b: ->(c){5}
    }
  end

  let(:cyclical_map) do
    {
      a: ->(c){c[:b]},
      b: ->(c){c[:c]},
      c: ->(c){c[:a]}
    }
  end

  let(:non_callable_map){ {moho:'foo'} }

  let(:handler) do
    {
      handler: Proc.new do |c|
        begin
          c[:a]
        rescue => e
          [e, c.callstack]
        end
      end
    }
  end

  describe 'call' do

    it 'should alias :[] to call' do
      context = Reduxco::Context.new
      context.method(:[]).should == context.method(:call)
    end

    it 'should invoke the call method of the object it resolves to' do
      callable = double('callable')
      context = Reduxco::Context.new(:moho => callable)

      callable.should_receive(:call).with(context)

      context.call(:moho)
    end

    it 'should resolve a leaf refname to a value' do
      context = Reduxco::Context.new(add_map)
      context.call(:a).should == 3
    end

    it 'should resolve a refname with dependencies to a value via cascading calculation' do
      context = Reduxco::Context.new(add_map)
      context.call(:sum).should == 8
    end

    describe 'errors' do

      it 'should error if refname resolves to a non-callable' do
        context = Reduxco::Context.new(non_callable_map)

        ->{ context.call(:moho) }.should raise_error(Reduxco::Context::NotCallableError)

        begin
          context.call(:moho)
        rescue => e
          e.message.should include('moho')
          e.backtrace.select {|tr| tr.include?('context.rb')}.should == []
        end
      end

      it 'should error if refname is non-resolvable' do
        context = Reduxco::Context.new(add_map)

        ->{ context.call(:eeloo) }.should raise_error(Reduxco::Context::NameError)

        begin
          context.call(:eeloo)
        rescue => e
          e.message.should include('eeloo')
          e.backtrace.select {|tr| tr =~ /context.rb.+`call'$/}.should == []
        end

      end

      it 'should error on cyclical dependencies' do
        context = Reduxco::Context.new(cyclical_map)

        ->{ context.call(:a) }.should raise_error(Reduxco::Context::CyclicalError)

        begin
          context.call(:a)
        rescue => e
          e.message.should include('a:1')
          e.message.should include('c:1')
          e.backtrace.select {|tr| tr =~ /context.rb.+`call'$/}.should == []
        end
      end

      it 'should not corrupt the callstack when catching a non-resolvalbe name error' do
        context = Reduxco::Context.new({a:->(c){c[:eeloo]}}, handler)

        error, stack = context.call(:handler)

        stack.top.should == Reduxco::CallableRef.new(:handler, 2)
        stack.depth.should == 1
      end

      it 'should not corrupt the callstack when catching a cyclical dependency' do
        context = Reduxco::Context.new(cyclical_map, handler)

        error, stack = context.call(:handler)

        stack.top.should == Reduxco::CallableRef.new(:handler, 2)
        stack.depth.should == 1
      end

    end

  end

  describe 'callstack interface' do

    it 'should return a copy of the callstack' do
      context = Reduxco::Context.new

      context.callstack.should be_kind_of(Reduxco::Context::Callstack)
      context.callstack.should.object_id.should_not == context.callstack
    end

    it 'should return a copy of the callstack from inside of a call' do
      context = Reduxco::Context.new({
        app: ->(c){ c.callstack }
      })

      stack = context.call(:app)

      stack.depth.should == 1
      stack.top.name.should == :app
    end

    it 'should return the current frame' do
      context = Reduxco::Context.new({
        app: ->(c){ c.current_frame.should == c.callstac.top }
      })
    end

  end

  describe 'super' do

    it 'should resolve to the next previous ref of the same name'

    it 'should chain calls and their results'

    it 'should throw a NameError if super cannot be resolved'

  end

  describe 'introspection interface' do

    it 'should introspect which refnames are valid.'

    it 'should introspect which callrefs are valid.'

    it 'should introspect which refnames have been computed.'

    it 'should introspect which callrefs have been computed.'

  end

  describe 'initialization' do

    it 'should initialize with a single callable map'

    it 'should initialize with multiple callable maps'

    it 'should only invoke :each on the map (returning name/callable pairs)'

  end

  describe 'run' do

    it 'should run with a refname and return the result'

    it 'should run with :app by default'

    it 'should allow access to locals inside of callables'

  end

  describe 'flow helpers' do

    describe 'before' do

      it 'should invoke the before helper block before calling the passed refname'

      it 'should return the value of the passed refname'

    end

    describe 'after' do

      it 'should invoke the after helper block after calling the passed refname'

      it 'should return the value of the passed refname'

    end

    describe 'inside' do

      it 'should make the helper block available to the passed refname'

      it 'should allow calling the block from inside the passed refname'

      it 'should return the block\'s value reom inside the passed refname'

      it 'should return the value of the passed refname'

    end

  end

end
