# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'renum/version'

Gem::Specification.new do |gem|
  gem.name          = "renum"
  gem.version       = Renum::VERSION
  gem.authors       = ["jake"]
  gem.email         = ["pablo_honey@me.com"]
  gem.description   = %q{Ruby Enum storage.}
  gem.summary       = %q{Store some things vaguely similar to enums. In Ruby}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_dependency 'redis-namespace'
end
