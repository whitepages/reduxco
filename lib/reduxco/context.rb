require_relative 'callable_ref'
require_relative 'context/callable_table'
require_relative 'context/callstack'

module Reduxco
  class Context

    def initialize(*callable_maps)
      @callable_maps = callable_maps
      @calltable = CallableTable.new(@callable_maps)

      @callstack = Callstack.new
      @cache = {}
    end

    attr_reader :locals

    def run(ref_name=:app, locals)
      @locals = locals
      self[:app]
    end

    def call(ref_name)
      # First, we resolve the callref and add it to the callstack.
      frame, callable = @calltable.resolve( CallableRef.new(ref_name) )
      @callstack.push(frame)

      # Once we've added to teh callstack, we must do all work in an ensure so
      # that exception handling callables still work!
      begin
        # If the ref is already in the stack, then we have a cyclical dependency.
        if( @callstack.rest.include?(frame) )
          raise RuntimeError, "Cyclical dependency on #{frame.inspect} in #{@callstack.rest.top.inspect} via #{@callstack.inspect}", caller
        end

        # Recall from cache, or build if necessary.
        unless( @cache.include?(frame) )
          @cache[frame] = callable.respond_to?(:call) ? callable.call(self) : raise(RuntimeError, "#{frame} does not resolve to a callable.", caller)
        end
        @cache[frame]
      ensure
        # No matter what crashes happened, we must ensure we pop the frame off the stack.
        popped = @callstack.pop
        raise RuntimeError, "Corrupt Callstack: #{popped} != #{frame}" if popped != frame
      end
    end
    alias_method :[], :call

    def super(ref_name)
      callref = CallableRef.new(ref_name)
    end

    def callstack
      @callstack.dup
    end

    def current_frame
      @callstack.top
    end

  end
end
