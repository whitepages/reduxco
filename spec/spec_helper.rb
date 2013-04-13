require 'reduxco'

# Require the debugger, if present.
begin
  require 'debugger'
rescue LoadError
  module Kernel
    def debugger(*args, &block)
      STDERR.puts "*** Debugger not available."
    end
  end
end
