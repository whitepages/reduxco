module Reduxco
  class Context
    # Defines and implements a callstack interface.
    #
    # Callstacks are made of frames, and the top element of the stack is the
    # current frame.
    class Callstack

      # Initialize an empty callstack.  Optionally takes an array of frames,
      # reading from top of the stack to the bottom.
      def initialize(array=[])
        @stack = array.reverse
      end

      # Pushes the given frame onto the callstack
      def push(frame)
        @stack.push(frame)
        self
      end

      # Pops the top frame from the callstack and returns it.
      def pop
        @stack.pop
      end

      # Returns the element at the top of the stack.
      def top
        @stack.last
      end

      # Returns the element at a given depth from the top of the stack.
      #
      # A depth of zero corresponds to the top of the stack.
      def peek(depth)
        @stack[-depth - 1]
      end

      # Returns true if the callstack contains the given frame
      def include?(frame)
        @stack.include?(frame)
      end

      # Returns teh callstack depth
      def depth
        @stack.length
      end

      # Returns a Callstack instance for everything below the top of the stack.
      def rest
        self.class.new(@stack[0..-2].reverse)
      end

      # Returns a copy of this callstack.
      def dup
        self.class.new(@stack.dup.reverse)
      end

      # Returns the callstack in a form that looks like Ruby's caller method,
      # so that it can be placed in exception backtraces.  Typically one wants
      # the top of the caller-style stack to be the trace to where Context#call was
      # invoked in a caller, so this may be provided.
      def to_caller(top=nil)
        @stack.reverse.map {|frame| "#{self.class.name} frame: #{frame}"}.tap do |cc|
          cc.unshift top.to_s unless top.nil?
        end
      end

      # Output the Callstack from top to bottom.
      def to_s
        @stack.reverse.to_s
      end

      # Inspect the Callstack, with the top frame first.
      def inspect
        @stack.reverse.inspect
      end

    end
  end
end

