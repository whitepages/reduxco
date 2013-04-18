require 'spec_helper'

describe Reduxco::Reduxer do

  # Helper to make a Reduxer and set the context to anything desired.
  def reduxer_with_context(context)
    Reduxco::Reduxer.allocate.tap {|r| r.instance_variable_set(:@context, context)}
  end

  describe 'reduce' do

    it 'should alias call to reduce'

    it 'should alias [] to reduce'

    it 'should delegate call to its context'

  end

  describe 'initialize' do

    it 'should initialize with callable maps'

    it 'should initialize with a copy of a Context when it is the first argument'

  end

  describe 'dup' do

    it 'should create a new Reduxer with a new Context'

    it 'should dup with the same callable maps.'

  end

  describe 'general' do

    it 'should provide access to the wrapped context' do
      context = double('context')
      reduxer = reduxer_with_context(context)
      reduxer.context.should == context
    end

  end

end
