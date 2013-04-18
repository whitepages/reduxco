require_relative 'context'

module Reduxco
  # The primary public facing Reduxco class.
  class Reduxer

    # When given one or more maps of callables, instantiates with the given
    # callable maps.
    #
    # When the first argument is a Context, it instantiates with a new Context
    # that has the same callable maps.
    def initialize(*args)
      case args.first
      when Context
        @context = args.first.dup
      else
        @context = Context.new(*args)
      end
    end

    # Returns a reference to the enclosing Context.  This is typically not
    # needed, and its use is more often than not related to a client design
    # mistake.
    attr_reader :context

    def call(refname=:app)
      @context.call(refname)
    end
    alias_method :[], :call
    alias_method :reduce, :call

    # Acts as a copy constructor, giving a new Reduxer instantiated with the
    # same arguments as this one.
    def dup
      self.class.new(@context)
    end

  end
end
