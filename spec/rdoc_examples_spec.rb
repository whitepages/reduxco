require 'spec_helper'

describe 'RDoc Examples' do

  describe 'README.rdoc' do

    it 'should meet the math example' do
      srand(5) # For test predictability

      ###

      callables = {
             x: ->(c){ rand(10) },
             y: ->(c){ rand(10) },
           sum: ->(c){ c[:x] + c[:y] },
        result: ->(c){ c[:sum] * c[:sum] },
           app: ->(c){ "For x=#{c[:x]} and y=#{c[:y]}, the result is #{c[:result]}." }
      }

      pipeline = Reduxco::Reduxer.new(callables)
      output = pipeline.reduce
      output.should == "For x=3 and y=6, the result is 81."

      ###

      pipeline.reduce(:sum).should == 9

      ###

      srand(Time.now.to_i) # And now randomize better again.
    end

    it 'should meet the error handling exampmle' do
      # The base callables, probably served up from a factory.
      base_callables = {
        app: ->(c) do
          c.inside(:error_handler) do
            c[:value].even? ? raise(RuntimeError, "Even!") : c[:value]
          end
        end,

        error_handler: ->(c) do
          begin
            c.yield
          rescue => error
            c.call(:onfailure){error} if c.include?(:onfailure)
          end
        end,

        value: ->(c){ rand(100) },
      }

      # The contect specific eror handler implementation.
      handler_callables = {
        onfailure: ->(c){ c.yield.message }
      }

      # Test callables; overrieds the value to be an even value.
      even_test_callables = {
        value: ->(c){ 8 }
      }

      # Test callables: overrieds the value to be an odd value.
      odd_test_callables = {
        value: ->(c){ 13 }
      }

      # Test evens
      pipeline = Reduxco::Reduxer.new(base_callables, handler_callables, even_test_callables)
      pipeline.reduce.should == 'Even!'

      # Test odds
      pipeline = Reduxco::Reduxer.new(base_callables, handler_callables, odd_test_callables)
      pipeline.reduce.should == 13

      # Invoke with random result
      pipeline = Reduxco::Reduxer.new(base_callables, handler_callables)
      random_result = pipeline.reduce
    end

    it 'should obey basic context use' do
      map = {
        sum: ->(c){ c[:x] + c[:y] },
          x: ->(c){ 3 },
          y: ->(c){ 5 }
      }

      pipeline = Reduxco::Reduxer.new(map)
      sum = pipeline.reduce(:sum)
      sum.should == 8
    end

    it 'should have a basic app pipeline example' do
      pipeline = Reduxco::Reduxer.new(app: ->(c){ "Hello World" })
      result = pipeline.reduce
      result.should == "Hello World"
    end

    it 'should have a simple yield example' do
      callables = {
        app: ->(c){ c.call(:foo) {3+20} },
        foo: ->(c){ c.yield + 100 }
      }

      pipeline = Reduxco::Reduxer.new(callables)
      pipeline.reduce.should == 123
    end

    it 'should override/shadow' do
      map1 = {
        message: ->(c){ 'Hello From Map 1' }
      }

      map2 = {
        message: ->(c){ 'Hello From Map 2' }
      }

      msg = Reduxco::Reduxer.new(map1, map2).reduce(:message)
      msg.should == 'Hello From Map 2'
    end

    it 'should super' do
      map1 = {
        message: ->(c){ 'Hello From Map 1' }
      }

      map2 = {
        message: ->(c){ c.super + ' and Hello From Map 2' }
      }

      msg = Reduxco::Reduxer.new(map1, map2).reduce(:message)
      msg.should == 'Hello From Map 1 and Hello From Map 2'
    end

  end

end
