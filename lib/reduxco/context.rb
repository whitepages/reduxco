require_relative 'callable_ref'

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

    private

    def flatten
    end

  end
end

module Reduxco
  class Context
    # CallableTable is a 'private' helper class to Context which handles resolving
    # CallableRef instances to their appropriate callables.  This should not be
    # used directly.
    class CallableTable

      # Instantiate with list of callable maps.
      def initialize(callable_map_list)
        @table = Hash[flatten(callable_map_list).sort.reverse]
      end

      # Resolves the given callref.  Has a multivalued return of the form
      # [matching_callref, callable] if the callref.  If the ref cannot be found, then
      # the callable value will be nil.
      def resolve(callref)
        if( callref.static? )
          @table.include?(callref) ? [callref, @table[callref]] : [nil, nil]
        else
          @table.find(->{[nil,nil]}) {|refkey, callable| callref.include?(refkey)}
        end
      end
      alias_method :[], :resolve

      # Returns true if the call with teh given callref exists.
      def include?(callref)
        !resolve(callref).last.nil?
      end

      # Given a static callref, resolves the next available shadowed callable
      # above it.  If the callref is dynamic, then an exception is thrown.
      def resolve_super(callref)
        if( callref.dynamic? )
          raise ArgumentError, "Cannot resolve the 'super' of a dyanmic CallableReference.", caller
        else
          #TODO: It may be more efficient to brute force try each depth until one is found.
          @table.find(->{[nil,nil]}) {|refkey, callable| refkey.name == callref.name && refkey.depth < callref.depth}
        end
      end

      private

      # Flattens the given list of independent maps into a flat symbol table.
      def flatten(callable_map_list)
        callable_map_list.each_with_object({table:{}, depth:1}) do |map, memo|
          map.each do |name, callable|
            memo[:table][CallableRef.new(name, memo[:depth])] = callable
          end
          memo[:depth] += 1
        end[:table]
      end

    end
  end
end
