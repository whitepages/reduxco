module Reduxco
  class Context
    # Defines and implements a callstack interface.
    #
    # Callstacks are made of frames, and the top element of the stack is the
    # current frame.
    class Callstack

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

