# -*- encoding: utf-8 -*-
$LOAD_PATH.push File.expand_path('../lib', __FILE__)
require 'reduxco/version'

Gem::Specification.new do |s|
  s.name = 'reduxco'
  s.version = Reduxco::VERSION
  s.platform = Gem::Platform::RUBY
  s.authors = ['Jeff Reinecke']
  s.email = ['jreinecke@whitepages.com']
  s.homepage = 'https://github.com/whitepages/reduxco'
  s.summary = 'A graph reduction calculation engine.'
  s.description = "Reduxco is a general purpose graph reduction calculation engine for those\nnon-linear dependency flows that normal pipelines and Rack Middleware-like\narchitectures can't do cleanly."
  s.licenses = ['BSD']

  s.has_rdoc = true
  s.extra_rdoc_files = ['README.rdoc']

  s.files = Dir.glob("{lib,spec}/**/*") + ['README.rdoc', 'LICENSE.txt', 'Rakefile']
  s.require_paths = ['lib']
end
