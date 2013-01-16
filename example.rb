#!/usr/bin/env ruby

# Ruby 1.9 doesn't include the current
# working directory on the load path.
$: << Dir.pwd + '/lib/'

# Automatically sucks in the `sshkit`
# files so that you don't need to.
require 'sshkit/dsl'

directory = '/opt/sites/web_application'
hosts     = SSHKit::Host.new("root@example.com")

SSHKit.config.output = SSHKit::Formatter::Pretty.new($stdout)

on hosts do |host|
  target = '/opt/rack-rack-repository'
  if host.hostname =~ /seven/
    target = '/var/rack-rack-repository'
  end
  if execute(:test, "-d #{target}")
    within target do
      execute :git, :pull
    end
  else
    execute :git, :clone, 'git://github.com/rack/rack.git', target
  end
end
