source 'https://rubygems.org'

gemspec

group :development do
  gem 'rake'
  gem 'rdoc', ">= 2.4.2" if( RUBY_VERSION < '1.9.3' ) # Rake 10.0.4 requires rdoc >= 2.4.2 to work; 1.9.2 doesn't do this by default.
  gem 'debugger'
end

group :test do
  gem 'rake'
  gem 'rspec', '~>2.13'
end
