require 'spec_helper'

describe Reduxco::CallableRef do

  describe 'basic properites' do

    it 'should error if the depth is 0 or less.' do
      ->{Reduxco::CallableRef.new(:foo, 0)}.should raise_error(IndexError)
      ->{Reduxco::CallableRef.new(:foo, -100)}.should raise_error(IndexError)
    end

    it 'should be dynamic with a symbol name' do
      ref = Reduxco::CallableRef.new(:foo)
      ref.should be_dynamic
      ref.should_not be_static
    end

    it 'should be static with a symbol name and depth' do
      ref = Reduxco::CallableRef.new(:foo, 3)
      ref.should be_static
      ref.should_not be_dynamic
    end

    it 'should give the name' do
      ref = Reduxco::CallableRef.new(:foo)
      ref.name.should == :foo
    end

    it 'should give the depth' do
      ref = Reduxco::CallableRef.new(:foo, 3)
      ref.depth.should == 3
    end

    it 'should give nil for the depth of a dynamic ref' do
      ref = Reduxco::CallableRef.new(:foo)
      ref.depth.should be_nil
    end

    it 'should be immutable' do
      ref = Reduxco::CallableRef.new(:foo)
      ref.should_not respond_to(:name=)
      ref.should_not respond_to(:depth=)
    end

    it 'should accept non-symbol names' do
      name = Object.new
      ref = Reduxco::CallableRef.new(name)
      ref.name.should == name
    end

    it 'should not change strings to symbols' do
      ref = Reduxco::CallableRef.new('foo')
      ref.name.should_not == :foo
      ref.name.should == 'foo'
    end

  end

  describe 'movement' do

    describe 'succ' do

      it 'should return a ref with the same name, but one level deeper' do
        name = Object.new
        ref = Reduxco::CallableRef.new(name, 10)

        ref.succ.tap do |r|
          r.name.should == name
          r.depth.should == 11
        end
      end

      it 'should raise an exception when dynamic' do
        ->{ Reduxco::CallableRef.new(:foo).succ }.should raise_error
      end

      it 'should alias next to succ' do
        ref = Reduxco::CallableRef.new('foo')
        ref.method(:next).should == ref.method(:succ)
      end

    end

    describe 'pred' do

      it 'should return a ref with the same name, but one level higher' do
        name = Object.new
        ref = Reduxco::CallableRef.new(name, 10)

        ref.pred.tap do |r|
          r.name.should == name
          r.depth.should == 9
        end
      end

      it 'should raise an exception when stepping too low' do
        name = Object.new
        ref = Reduxco::CallableRef.new(name, 1)

        ->{ ref.pred }.should raise_error(IndexError)
      end

      it 'should raise an exception when dynamic' do
        ->{ Reduxco::CallableRef.new(:foo).succ }.should raise_error
      end

    end

  end

  describe 'equality' do

    it 'should compute a predictable hash based on name' do
      name = Object.new
      ref1 = Reduxco::CallableRef.new(name)
      ref2 = Reduxco::CallableRef.new(name)
      refz = Reduxco::CallableRef.new(Object.new)

      ref2.hash.should == ref1.hash
      refz.hash.should_not == ref1.hash
    end

    it 'should compute a predictable hash based on depth' do
      ref1 = Reduxco::CallableRef.new(:foo, 3)
      ref2 = Reduxco::CallableRef.new(:foo, 3)
      refy = Reduxco::CallableRef.new(:foo)
      refz = Reduxco::CallableRef.new(:foo, 4)

      ref2.hash.should == ref1.hash
      refy.hash.should_not == ref1.hash
      refz.hash.should_not == ref1.hash
    end

    it 'should compute different hashes for a string and symbol name' do
      Reduxco::CallableRef.new(:foo).hash.should_not == Reduxco::CallableRef.new('foo').hash
    end

    it 'should compute static refs as included in a same-named dynamic ref' do
      ref = Reduxco::CallableRef.new(:foo)

      ref1 = Reduxco::CallableRef.new(:foo, 3)
      ref2 = Reduxco::CallableRef.new(:foo, 4)
      ref3 = Reduxco::CallableRef.new(:bar, 4)
      ref4 = Reduxco::CallableRef.new(:foo)

      ref.should include(ref1)
      ref.should include(ref2)
      ref.should_not include(ref3)
      ref.should include(ref4)
    end

    it 'should compute dynamic refs as only equal to dynamic refs with the same name' do
      ref = Reduxco::CallableRef.new(:foo)

      ref1 = Reduxco::CallableRef.new(:foo)
      ref2 = Reduxco::CallableRef.new(:foo, 4)

      ref1.should == ref
      ref2.should_not == ref
    end

    it 'should compute static refs as only equal to refs with the same name and depth' do
      ref = Reduxco::CallableRef.new(:foo, 4)

      ref1 = Reduxco::CallableRef.new(:foo)
      ref2 = Reduxco::CallableRef.new(:foo, 3)
      ref3 = Reduxco::CallableRef.new(:foo, 4)

      ref1.should_not == ref
      ref2.should_not == ref
      ref3.should == ref
    end

    it 'should not consider a string value of a ref equal to the ref' do
      ref = Reduxco::CallableRef.new(:foo, 4)
      ref.should_not == ref.to_s
    end

  end

  describe 'sortability' do

    it 'should not allow sorting of dynamic refs with static ones' do
      refs = [[:foo,3], [:bar]].map {|args| Reduxco::CallableRef.new(*args)}
      ->{refs.sort}.should raise_error(ArgumentError)
    end

    it 'should sort equivalently named refs of lower depth above those of higher depths' do
      depths = [6,1,2,2,9]
      refs = depths.map {|depth| Reduxco::CallableRef.new(:foo, depth)}

      refs.sort.map {|ref| ref.depth}.should == depths.sort
    end

    it 'should sort names of same depth when sortable' do
      names = ['cdr', 'cons', 'car']
      dyn_refs = names.map {|name| Reduxco::CallableRef.new(name)}
      stc_refs = names.map {|name| Reduxco::CallableRef.new(name, 3)}

      dyn_refs.sort.map {|ref| ref.name}.should == names.sort
      stc_refs.sort.map {|ref| ref.name}.should == names.sort
    end

    it 'should not reject unsortable names (just be ambiguous)' do
      names = [3, nil, :foo, Object.new]
      dyn_refs = names.map {|name| Reduxco::CallableRef.new(name)}
      stc_refs = names.map {|name| Reduxco::CallableRef.new(name, 3)}

      ->{ dyn_refs.sort.map {|ref| ref.name} }.should_not raise_error
      ->{ stc_refs.sort.map {|ref| ref.name} }.should_not raise_error
    end

  end

  describe 'coercion' do

    before(:each) do
      @dyn_ref = Reduxco::CallableRef.new(:foo)
      @stc_ref = Reduxco::CallableRef.new(:foo, 3)
    end

    it 'should convert to string' do
      @dyn_ref.to_s.should == @dyn_ref.name.to_s
      @stc_ref.to_s.split(Reduxco::CallableRef::SEPARATOR).should == [@stc_ref.name, @stc_ref.depth].map {|v| v.to_s}
    end

    it 'should convert to array' do
      @dyn_ref.to_a.should == [@dyn_ref.name, @dyn_ref.depth]
      @stc_ref.to_a.should == [@stc_ref.name, @stc_ref.depth]
    end

    it 'should convert to hash' do
      @dyn_ref.to_h.should == {name: @dyn_ref.name, depth: @dyn_ref.depth}
      @stc_ref.to_h.should == {name: @stc_ref.name, depth: @stc_ref.depth}
    end

    it 'should not convert to string a missing splat like it had one' do
      Reduxco::CallableRef.new([:foo,3]).to_s.should_not == Reduxco::CallableRef.new(:foo,3).to_s
    end

  end

end
