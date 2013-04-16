require_relative 'callable_ref'
require_relative 'context/callable_table'

module Reduxco
  class Context

    def initialize(*callable_maps)
      @callable_maps = callable_maps
      @calltable = CallableTable.new(@callable_maps)
    end

    attr_reader :locals

    def run(callref=CallableRef.new(:app), locals)
      @locals = locals
      self[:app]
    end

    def call(callref)
    end
    alias_method :[], :call

    def super(callref)
      # Callref should have a 'super' method that returns a ref that is one depth higher.
    end

  end
end
