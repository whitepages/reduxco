require_relative '../callable_ref'

module Reduxco
  class Context
    # CallableTable is a 'private' helper class to Context which handles resolving
    # CallableRef instances to their appropriate callables.  This should not be
    # used directly.
    class CallableTable

      # The constant returned by +resolve+ when resolution failure occurs.
      # This constant can be multiply assigned to the same pattern as a
      # normal resolution, but will assign nil into each value.
      RESOLUTION_FAILURE = [nil,nil]

      # Instantiate with list of callable maps.
      def initialize(callable_map_list)
        @table = Hash[flatten(callable_map_list).sort.reverse]
      end

      # Resolves the given callref.  The return value usually takes advantage of
      # multiple assignment to dissect the return into the matching callref and
      # found callable. however one can check for failed resolution simply by
      # comparing the result to RESOLUTION_FAILURE.
      #
      # Note that if resolution fails, each value in the multiple assignment is
      # given the value nil.
      def resolve(callref)
        if( callref.static? )
          @table.include?(callref) ? [callref, @table[callref]] : RESOLUTION_FAILURE
        else
          @table.find(->{RESOLUTION_FAILURE}) {|refkey, callable| callref.include?(refkey)}
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
          # This is really nice, but runs in O(n):
          #   @table.find(->{RESOLUTION_FAILURE}) {|refkey, callable| refkey.name == callref.name && refkey.depth < callref.depth}
          # This is more performant on large tables O(1) but has the potential for a lot of recursion depth:
          #   if( callref.depth <= CallableRef::MIN_DEPTH )
          #     RESOLUTION_FAILURE
          #   else
          #     resolution = resolve(callref.pred)
          #     resolution == RESOLUTION_FAILURE ? resolve_super(callref.pred) : resolution
          #   end
          # So we go for this imperative C-style flat iteration for O(1) and no recursion.
          ref = callref
          while( ref.depth > CallableRef::MIN_DEPTH )
            ref = ref.pred
            resolution = resolve(ref)
            return resolution if(resolution != RESOLUTION_FAILURE)
          end
          RESOLUTION_FAILURE
        end
      end

      private

      # Flattens the given list of independent maps into a flat symbol table.
      def flatten(callable_map_list)
        callable_map_list.each_with_object({table:{}, depth:CallableRef::MIN_DEPTH}) do |map, memo|
          map.each do |name, callable|
            memo[:table][CallableRef.new(name, memo[:depth])] = callable
          end
          memo[:depth] += 1
        end[:table]
      end

    end
  end
end
