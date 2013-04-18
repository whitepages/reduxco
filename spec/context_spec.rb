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

    it 'should resolve a callref' do
      context = Reduxco::Context.new(add_map)
      context.call( Reduxco::CallableRef.new(:sum) ).should == 8
    end

    it 'should resolve a callref to a shadowed value' do
      context = Reduxco::Context.new(add_map, {sum: ->(c){-101}})
      context.call( Reduxco::CallableRef.new(:sum, 1) ).should == 8
      context.call( Reduxco::CallableRef.new(:sum, 2) ).should == -101
    end

    it 'should cache the results' do
      context = Reduxco::Context.new(app: ->(c){ Object.new })

      generated_object = context.call(:app)
      context.call(:app).should == generated_object
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

  describe 'super' do

    it 'should resolve to the next previous ref of the same name' do
      context = Reduxco::Context.new({
        moho: ->(c){ 'top' }
      },
      {
        moho: ->(c){ c.super }
      })

      context.call(:moho).should == 'top'
    end

    it 'should chain calls and their results' do
      context = Reduxco::Context.new({
        moho: ->(c){ 1 }
      },
      {
        moho: ->(c){ c.super + 2 }
      },
      {
        eve: ->(c){ 1024 }
      },
      {
        moho: ->(c){ c.super + 4 }
      })

      context.call(:moho).should == 7
    end

    it 'should throw a NameError if super cannot be resolved' do
      context = Reduxco::Context.new({
        eve: ->(c){ 'eve' }
      },
      {
        moho: ->(c){ c.super }
      })

      ->{ context.call(:moho) }.should raise_error(Reduxco::Context::NameError)
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

  describe 'introspection interface' do

    let(:map1) do
      {moho: ->(c){'moho-value'}, eve: ->(c){'eve-value'}}
    end

    let(:map2) do
      {kerbin: ->(c){'kerbin-value'}, duna: ->(c){'duna-value'}, app: ->(c){c[:kerbin] + c[:moho]}}
    end

    let(:context) do
      Reduxco::Context.new(map1, map2)
    end

    describe 'include' do

      it 'should introspect which refnames are valid.' do
        context.include?(:moho).should be_true
        context.include?(:kerbin).should be_true

        context.include?(:eeloo).should be_false
      end

      it 'should introspect which dynamic callrefs are valid.' do
        context.include?( Reduxco::CallableRef.new(:moho) ).should be_true
        context.include?( Reduxco::CallableRef.new(:kerbin) ).should be_true
        context.include?( Reduxco::CallableRef.new(:eeloo) ).should be_false
      end

      it 'should introspect which static callrefs are valid.' do
        context.include?( Reduxco::CallableRef.new(:moho,1) ).should be_true
        context.include?( Reduxco::CallableRef.new(:kerbin,2) ).should be_true
        context.include?( Reduxco::CallableRef.new(:moho,2) ).should be_false
        context.include?( Reduxco::CallableRef.new(:kerbin,1) ).should be_false
      end

    end

    describe 'completed' do

      it 'should introspect which refnames have been computed.' do
        [:moho, :eve, :kerbin, :duna, :app].each do |refname|
          context.completed?(refname).should be_false
        end

        context.call(:app)

        [:moho, :kerbin, :app].each do |refname|
          context.completed?(refname).should be_true
        end

        [:eve, :duna].each do |refname|
          context.completed?(refname).should be_false
        end
      end

      it 'should introspect which callrefs have been computed.' do
        all_ref_args = [[:kerbin,1], [:kerbin,2], [:moho,1], [:moho,2], [:duna,1], [:duna,2]]

        all_ref_args.each do |name, depth|
          callref = Reduxco::CallableRef.new(name, depth)
          context.completed?(callref).should be_false
        end

        context.call(:app)

        completed_ref_args = [[:kerbin,2], [:moho,1]]
        incomplete_ref_args = all_ref_args - completed_ref_args

        completed_ref_args.each do |name, depth|
          callref = Reduxco::CallableRef.new(name, depth)
          context.completed?(callref).should be_true
        end

        incomplete_ref_args.each do |name, depth|
          callref = Reduxco::CallableRef.new(name, depth)
          context.completed?(callref).should be_false
        end
      end

      it 'should report not-found refs as uncomputed.' do
        context.completed?(:eeloo).should be_false
        context.completed?( Reduxco::CallableRef.new(:eloo,1) ).should be_false
      end

    end

    describe 'assert_completed' do

      it 'should raise an exception if failed' do
        ->{ context.assert_completed(:app) }.should raise_error(Reduxco::Context::AssertError)
      end

      it 'should return nil if success' do
        context[:app]

        context.assert_completed(:app).should be_nil
      end

    end

  end

  describe 'initialization' do

    let(:map1) { {moho: ->(c){'moho1'}} }
    let(:map2) { {eve: ->(c){'eve2'}} }

    it 'should initialize with a single callable map' do
      context = Reduxco::Context.new(map1)
      context.should include(:moho)
    end

    it 'should initialize with multiple callable maps' do
      context = Reduxco::Context.new(map1, map2)
      context.should include(:moho)
      context.should include(:eve)
    end

    it 'should only invoke :each on the map (returning name/callable pairs)' do
      map = double('map')
      map.should_receive(:each)

      Reduxco::Context.new(map)
    end

  end

  describe 'duplication' do

    it 'should instantiate a new Context with the same callables on dup' do
      map1 = double('map1')
      map1.stub(:each)
      map2 = double('map2')
      map2.stub(:each)
      context = Reduxco::Context.new(map1, map2)

      dup = context.dup

      dup.instance_variables.each do |ivar|
        dup.instance_variable_get(ivar).object_id.should_not == context.instance_variable_get(ivar)
      end

      dup.instance_variable_get(:@callable_maps).tap do |maps|
        maps.should == [map1, map2]
      end
    end

  end

  describe 'reduce' do

    it 'should reduce with a refname and return the result' do
      context = Reduxco::Context.new(app: ->(c){'app-result'})

      context.reduce(:app).should == 'app-result'
    end

    it 'should reduce with :app by default' do
      context = Reduxco::Context.new(app: ->(c){'app-result'})

      context.reduce(:app).should == 'app-result'
    end

  end

  describe 'flow helpers' do

    describe 'before' do

      it 'should invoke the before helper block before calling the passed refname' do
        call_order = []
        context = Reduxco::Context.new({
          app: ->(c){ c.before(:a) {c[:b]} },
            a: ->(c){ call_order << :a },
            b: ->(c){ call_order << :b }
        })

        context.call(:app)

        call_order.should == [:b, :a]
      end

      it 'should return the value of the passed refname' do
        context = Reduxco::Context.new({
          app: ->(c){ c.before(:a) {c[:b]} },
            a: ->(c){ 'a-result' },
            b: ->(c){ 'b-result' }
        })

        context.call(:app).should == 'a-result'
      end

      it 'should not yield anything to the block' do
        block_args = nil
        context = Reduxco::Context.new({
          app: Proc.new do |c|
            c.before(:a) do |*args|
              block_args = args
              c[:b]
            end
          end,
          a: ->(c){ 'a-result' },
          b: ->(c){ 'b-result' }
        })

        context.call(:app)

        block_args.should == []
      end

    end

    describe 'after' do

      it 'should invoke the after helper block after calling the passed refname' do
        call_order = []
        context = Reduxco::Context.new({
          app: ->(c){ c.after(:a) {c[:b]} },
            a: ->(c){ call_order << :a },
            b: ->(c){ call_order << :b }
        })

        context.call(:app)

        call_order.should == [:a, :b]
      end

      it 'should return the value of the passed refname' do
        context = Reduxco::Context.new({
          app: ->(c){ c.after(:a) {c[:b]} },
            a: ->(c){ 'a-result' },
            b: ->(c){ 'b-result' }
        })

        context.call(:app).should == 'a-result'
      end

      it 'should not yield anything' do
        block_args = nil
        context = Reduxco::Context.new({
          app: Proc.new do |c|
            c.after(:a) do |*args|
              block_args = args
              c[:b]
            end
          end,
          a: ->(c){ 'a-result' },
          b: ->(c){ 'b-result' }
        })

        context.call(:app)

        block_args.should == []
      end

    end

    describe 'inside' do

      describe 'client behavior' do

        let(:table){ {} }

        let(:outter) do
          Proc.new do |c|
            table[:yeild_result] = c.yield('arg1', 'arg2')
            'outter_result'
          end
        end

        let(:app) do
          Proc.new do |c|
            table[:inside_method_result] = c.inside(:outter) do |*args|
              table[:args] = args
              'yield_result'
            end
            'app_result'
          end
        end

        let(:map) do
          {app:app, outter:outter}
        end

        let(:context) do
          context = Reduxco::Context.new(map)
        end

        it 'should return the block\'s value from inside the passed refname' do
          context.call(:app)

          table[:yeild_result].should == 'yield_result'
        end

        it 'should return the value of the passed refname' do
          context.call(:app)


          table[:inside_method_result].should == 'outter_result'
        end

        it 'should allow yielding of args to the block' do
          context.call(:app)

          table[:args].should == ['arg1', 'arg2']
        end

        it 'should allow taking no block' do
          context = Reduxco::Context.new(app: ->(c){ c.inside(:outter) }, outter:outter)

          context.call(:app).should == 'outter_result'
        end

      end

      describe 'yield failure modes' do

        it 'should give nested insides their correct block handles'

        it 'should not corrupt the handle stack when an exception is thrown and then caught inside of nested insides'

        it 'should not allow yielding from a nested call.'

        it 'should not allow a double yield.'

      end

    end

  end

end
