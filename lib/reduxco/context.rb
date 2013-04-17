require_relative 'callable_ref'
require_relative 'context/callable_table'
require_relative 'context/callstack'

module Reduxco
  # Context is the client facing object for Reduxco.
  #
  # Typically, one instantiates a Context with one or more maps of callables
  # by name, and then calls +run+ to calculate all dependent nodes and return
  # a result.
  #
  # Maps may be any object that, when iterated with each, gives name/callable
  # pairs.
  #
  # Names may be any object that can serve as a hash key.
  #
  # Callables can be any object that responds to the call method.
  class Context

    # Special error type for halting due to a cyclic graph.
    class CyclicalError < StandardError; end

    # Special error type for when the callable provided has no call method.
    class NotCallableError < NoMethodError; end

    # A namespaced NameError for when the callref cannot be resolved.
    class NameError < ::NameError; end

    # Instantiate a Context with the one or more callalbe maps (e.g. hashes
    # whose keys are names and values are callable) for calculations.
    #
    # The further to the right in the arguments that a map is, the higher
    # the precedence of itsdefinition.
    def initialize(*callable_maps)
      @callable_maps = callable_maps
      @calltable = CallableTable.new(@callable_maps)

      @callstack = Callstack.new
      @cache = {}
    end

    # Accessor to the locals that are seeded on calls to run.
    attr_reader :locals

    # Invokes the given refname for this context (or uses :app by default),
    # returning the result.
    #
    # Must be provided a locals object, which can be any object but is usually
    # a Hash of special values for leaf nodes in the calculation.
    #
    # It is good practice to treat locals as immutable, leveraging the Context
    # calculation infrastructure to store intermediate values instead.
    def run(refname=:app, locals)
      @locals = locals
      self[:app]
    end

    # Given a refname, call it for this context and return the result.
    def call(refname)
      # First, we resolve the callref and invoke it.
      frame, callable = @calltable.resolve( CallableRef.new(refname) )

      # If the ref is nil then we couldn't resolve, otherwise invoke.
      if( frame.nil? )
        raise NameError, "No reference for name #{refname.inspect}", caller
      else
        invoke(frame, callable)
      end
    end
    alias_method :[], :call

    # When invoked, finds the next callable in the CallableTable up the chain
    # from the current frame, calls it, and returns the result.
    #
    # This is primarily used to reference shadowed callables in their overrides.
    def super
      # First, we resolve the super ref.
      frame, callable = @calltable.resolve_super( current_frame )

      # If the ref is nil then we couldn't resolve, otherwise invoke.
      if( frame.nil? )
        raise NameError, "No super found for #{current_frame}", caller
      else
        invoke(frame, callable)
      end
    end

    # Returns a copy of the current callstack.
    def callstack
      @callstack.dup
    end

    # Returns the top frame of the callstack.
    def current_frame
      @callstack.top
    end

    private

    # Invoke is the root method for all invocation of callables.
    #
    # It is given the frame to put on the stack (typically just a CallableRef),
    # and the callable to invoke.
    #
    # It is up to the callers of this method to resolve the callable that must
    # be called, or give a Reduxco::Context::NameError if it cannot be found.
    def invoke(frame, callable)
      #Push the frame onto the callstack.
      @callstack.push(frame)

      # Once we've added the frame to the callstack, we MUST do all work in
      # a begub/ensure so that exception handling callables get a consistent
      # callstack!
      begin
        # If the ref is already in the stack, then we have a cyclical dependency.
        if( @callstack.rest.include?(frame) )
          raise CyclicalError, "Cyclical dependency on #{frame.inspect} in #{@callstack.rest.top.inspect}", callstack.to_caller(caller[1])
        end

        # Recall from cache, or build if necessary.
        unless( @cache.include?(frame) )
          @cache[frame] = callable.respond_to?(:call) ? callable.call(self) : raise(NotCallableError, "#{frame} does not resolve to a callable.", caller[1..-1])
        end
        @cache[frame]
      ensure
        # No matter what crashes happened, we must ensure we pop the frame off the stack.
        popped = @callstack.pop
      end
    end

  end
end
