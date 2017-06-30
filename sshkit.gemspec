# -*- encoding: utf-8 -*-
require File.expand_path('../lib/sshkit/version', __FILE__)

Gem::Specification.new do |gem|

  gem.authors       = ["Lee Hambley", "Tom Clements"]
  gem.email         = ["lee.hambley@gmail.com", "seenmyfate@gmail.com"]
  gem.summary       = %q{SSHKit makes it easy to write structured, testable SSH commands in Ruby}
  gem.description   = %q{A comprehensive toolkit for remotely running commands in a structured manner on groups of servers.}
  gem.homepage      = "http://github.com/capistrano/sshkit"
  gem.license       = "MIT"

  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- test/*`.split("\n")
  gem.name          = "sshkit"
  gem.require_paths = ["lib"]
  gem.version       = SSHKit::VERSION

  gem.add_runtime_dependency('net-ssh',  '>= 2.8.0')
  gem.add_runtime_dependency('net-scp',  '>= 1.1.2')

  gem.add_development_dependency('danger')
  gem.add_development_dependency('minitest', '>= 5.0.0')
  gem.add_development_dependency('minitest-reporters')
  gem.add_development_dependency('rainbow', '~> 2.1.0')
  gem.add_development_dependency('rake')
  gem.add_development_dependency('rubocop', "~> 0.49.1")
  gem.add_development_dependency('mocha')

  gem.add_development_dependency('bcrypt_pbkdf')
  gem.add_development_dependency('rbnacl', '~> 3.4')
  gem.add_development_dependency('rbnacl-libsodium')
end
