# -*- encoding: utf-8 -*-
require File.expand_path('../lib/deploy/version', __FILE__)

Gem::Specification.new do |gem|

  gem.authors       = ["Lee Hambley", "Tom Clements"]
  gem.email         = ["lee.hambley@gmail.com", "seenmyfate@gmail.com"]
  gem.description   = %q{A comprehensive toolkit for remotely running commands and deploying software.}
  gem.homepage      = ""

  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.name          = "deploy"
  gem.require_paths = ["lib"]
  gem.version       = Deploy::VERSION

  gem.add_development_dependency('minitest', ['>= 2.11.3', '< 2.12.0'])
  gem.add_development_dependency('minitest', ['>= 2.11.3', '< 2.12.0'])
  gem.add_development_dependency('autotest')
  gem.add_development_dependency('rake')
  gem.add_development_dependency('turn')
  gem.add_development_dependency('mocha')
  gem.add_development_dependency('debugger')
  gem.add_development_dependency('vagrant')

end
