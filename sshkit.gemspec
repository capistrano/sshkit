# -*- encoding: utf-8 -*-
require File.expand_path('../lib/sshkit/version', __FILE__)

Gem::Specification.new do |gem|

  gem.authors       = ["Lee Hambley", "Tom Clements"]
  gem.email         = ["lee.hambley@gmail.com", "seenmyfate@gmail.com"]
  gem.summary       = %q{SSHKit makes it easy to write structured, testable SSH commands in Ruby}
  gem.description   = %q{A comprehensive toolkit for remotely running commands in a structured manner on groups of servers.}
  gem.homepage      = "http://github.com/capistrano/sshkit"
  gem.license       = "MIT"
  gem.metadata      = {
    "changelog_uri" => "https://github.com/capistrano/sshkit/releases"
  }

  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- test/*`.split("\n")
  gem.name          = "sshkit"
  gem.require_paths = ["lib"]
  gem.version       = SSHKit::VERSION
  gem.required_ruby_version = ">= 2.5"

  gem.add_runtime_dependency('base64')
  gem.add_runtime_dependency('logger')
  gem.add_runtime_dependency('net-ssh',  '>= 2.8.0')
  gem.add_runtime_dependency('net-scp',  '>= 1.1.2')
  gem.add_runtime_dependency('net-sftp', '>= 2.1.2')
  gem.add_runtime_dependency('ostruct')

  gem.add_development_dependency('danger')
  gem.add_development_dependency('minitest', '>= 5.0.0')
  gem.add_development_dependency('minitest-reporters')
  gem.add_development_dependency('rake')
  gem.add_development_dependency('rubocop', "~> 0.52.0")
  gem.add_development_dependency('mocha')

  gem.add_development_dependency('bcrypt_pbkdf')
  gem.add_development_dependency('ed25519', '>= 1.2', '< 2.0')
end
