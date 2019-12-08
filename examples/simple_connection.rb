# tiny example so you can play with the sshkit or make a failing example for an issue
require 'bundler/setup'
require 'sshkit'
require 'sshkit/dsl'
include SSHKit::DSL

on [ENV.fetch("HOST")] do
  execute "echo hello"
end
