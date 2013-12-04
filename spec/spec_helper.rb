require 'simplecov'
SimpleCov.start do
  add_filter {|sf| sf.filename !~ /\/lib\//}
end

require 'reduxco'

# Require the debugger, if present.
begin
  if( RUBY_VERSION < '2.0.0' )
    require 'debugger'
  else
    require 'byebug'
  end
rescue LoadError
  module Kernel
    def debugger(*args, &block)
      STDERR.puts "*** Debugger not available."
    end
  end
end

