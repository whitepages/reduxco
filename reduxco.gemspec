# -*- encoding: utf-8 -*-
$LOAD_PATH.push File.expand_path('../lib', __FILE__)
require 'reduxco/version'

Gem::Specification.new do |s|
  s.name = 'reduxco'
  s.version = Reduxco::VERSION
  s.platform = Gem::Platform::RUBY
  s.authors = ['Jeff Reinecke']
  s.email = ['jreinecke@whitepages.com']
  s.homepage = ''
  s.summary = 'A graph reduction calculation engine.'
  s.description = 'A graph reduction calculation engine inspired by combinators.'
  s.licenses = ['BSD']

  s.has_rdoc = true
  s.extra_rdoc_files = ['README.rdoc']

  s.files = Dir.glob("{lib,spec}/**/*") + ['README.rdoc', 'LICENSE.txt', 'Rakefile']
  s.require_paths = ['lib']
end
