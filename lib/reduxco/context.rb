require_relative 'callable_ref'
require_relative 'context/callable_table'
require_relative 'context/callstack'

module Reduxco
  # Context is the client facing object for Reduxco.
  #
  # Typically, one instantiates a Context with one or more maps of callables
  # by name, and then calls Contxt#reduce to calculate all dependent nodes and return
  # a result.
  #
  # Maps may be any object that, when iterated with each, gives name/callable
  # pairs. Names may be any object that can serve as a hash key. Callables can
  # be any object that responds to the call method.
  #
  # == Overview
  #
  # Context orchestrates the reduction calculation.  It is primarily used
  # by callables invoked during computation to get access to their environment.
  #
  # Instantiators of a Context typically only use the Context#reduce method.
  #
  # Users of Reduxco should use Reduxco::Reduxer rather than directly consume
  # Context directly.
  #
  # == Callable Helper Functions
  #
  # Callables (objects that respond to call) are the meat of the Context.
  # When their call method is invoked, it is passed a reference to the Context.
  # Callables can use this reference to access a range of methods, including
  # the following:
  #
  # [Context#call] Given a refname, run the associated callable and returns
  #                its value. Usually invoked as Context#[]
  # [Context#include?] Introspects if a refname is available.
  # [Context#completed?] Instrospects if a callable has been called and returned.
  # [Context#after] Given a refname and a block, runs the contents of the block
  #                 after the given refname, but returns the value of the callable
  #                 accociated with the refname.
  # [Context#inside] Given a refname and a block, runs the callable associated
  #                  with the refname, giving it access to running the block
  #                  inside of it and getting its value.
  class Context

    # Special error type for halting due to a cyclic graph.
    class CyclicalError < StandardError; end

    # Special error type for when the callable provided has no call method.
    class NotCallableError < NoMethodError; end

    # A namespaced NameError for when the callref cannot be resolved.
    class NameError < ::NameError; end

    # Special error type when Context assert methods fail. See +assert_computed+.
    class AssertError < StandardError; end

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

    # Given a refname, call it for this context and return the result.
    #
    # This can also take CallableRef instances directly, however if you find
    # yourself passing in static references, this is likely because of design
    # flaw in your callable map hierarchy.
    #
    # Call results are cached so that their values can be re-used.  If callables
    # have side-effects their side-effects are only invoked the first time
    # they are run.
    def call(refname=:app)
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
    alias_method :reduce, :call

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

    # Returns a true value if the given refname is defined in this context.
    #
    # If given a CallableRef, it returns a true value if the reference is
    # resolvable.
    def include?(refname)
      @calltable.resolve( CallableRef.new(refname) ) != CallableTable::RESOLUTION_FAILURE
    end

    # Returns a true value if the given refname has been computed.
    #
    # If the given CallableRef, it returns a true if the reference has already
    # been computed.
    def completed?(refname)
      callref = CallableRef.new(refname)
      key = callref.dynamic? ? @calltable.resolve(callref).first : callref
      @cache.include?(key)
    end

    # Raises an exception if +completed?+ is false.  Useful for asserting weak
    # dependencies (those which you do not need the return value of) have
    # been met.
    def assert_completed(refname)
      raise AssertError, "Assertion that #{refname} has completed failed.", caller unless completed?(refname)
    end

    # Runs the passed block before calling the passed refname.  Returns the
    # value of the call to refname.
    def before(refname)
      yield(self) if block_given?
      call(refname)
    end

    # Runs the passed block after calling the passed refname.  Returns the
    # value of the call to refname.
    def after(refname)
      result = call(refname)
      yield(self) if block_given?
      result
    end

    # Duplication of Contexts are dangerous because of all the deeply
    # nested structures.  That being said, it is very tempting to try
    # to use a well-constructed Context rather than save and reuse the
    # callable maps used for instantiation.
    #
    # To remedy this concern, dup acts as a copy constructor, making a new
    # Context instance with the same callable maps, but is otherwise
    # freshly constructed.
    def dup
      self.class.new(*@callable_maps)
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
