require 'pathname'
ENV['BUNDLE_GEMFILE'] ||= File.expand_path("../Gemfile", Pathname.new(__FILE__).realpath)
require 'rubygems'
require 'bundler/setup'

require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.rspec_opts = ['--backtrace']
end

require 'rdoc/task'

RDoc::Task.new do |rdoc|
  rdoc.rdoc_dir = "rdoc"
  rdoc.rdoc_files.add "lib/**/*.rb", "README.rdoc"
  rdoc.options << "--all"
  #rdoc.options << "--coverage-report" # Useful for finding something undocumented, but won't generate output when this is selected!
end
