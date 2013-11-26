# -*- encoding: utf-8 -*-
require File.expand_path('../lib/sshkit/version', __FILE__)

Gem::Specification.new do |gem|

  gem.authors       = ["Lee Hambley", "Tom Clements"]
  gem.email         = ["lee.hambley@gmail.com", "seenmyfate@gmail.com"]
  gem.summary       = %q{SSHKit makes it easy to write structured, testable SSH commands in Ruby}
  gem.description   = %q{A comprehensive toolkit for remotely running commands in a structured manner on groups of servers.}
  gem.homepage      = "http://github.com/capistrano/sshkit"

  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- test/*`.split("\n")
  gem.name          = "sshkit"
  gem.require_paths = ["lib"]
  gem.version       = SSHKit::VERSION

  gem.add_runtime_dependency('net-ssh')
  gem.add_runtime_dependency('net-scp', '>= 1.1.2')
  gem.add_runtime_dependency('term-ansicolor')

  gem.add_development_dependency('minitest', ['>= 2.11.3', '< 2.12.0'])
  gem.add_development_dependency('rake')
  gem.add_development_dependency('turn')
  gem.add_development_dependency('unindent')
  gem.add_development_dependency('mocha')
  gem.add_development_dependency('debugger')

  gem.add_development_dependency('yard')
  gem.add_development_dependency('redcarpet')

end
