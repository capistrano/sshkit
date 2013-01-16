#!/usr/bin/env ruby

# Ruby 1.9 doesn't include the current
# working directory on the load path.
$: << Dir.pwd + '/lib/'

# Automatically sucks in the `deploy`
# files so that you don't need to.
require 'deploy/dsl'
require 'forwardable'
require 'term/ansicolor'

directory = '/opt/sites/web_application'
hosts     = Deploy::Host.new("root@example.com")

#
# Custom output formatter!
#
class ColorizedFormatter < StringIO
  extend Forwardable
  attr_reader :original_output
  def_delegators :@original_output, :read, :rewind

  def initialize(oio)
    @original_output = oio
  end

  def write(obj)
    if obj.is_a? Deploy::Command
      unless obj.started?
        original_output << "[#{c.green(obj.uuid)}] Running #{c.yellow(c.bold(String(obj)))} on #{c.yellow(obj.host.to_s)}\n"
      end
      if obj.complete? && !obj.stdout.empty?
        obj.stdout.lines.each do |line|
          original_output << c.green("\t" + line)
        end
      end
      if obj.complete? && !obj.stderr.empty?
        obj.stderr.lines.each do |line|
          original_output << c.red("\t" + line)
        end
      end
      if obj.finished?
        original_output << "[#{c.green(obj.uuid)}] Finished in #{sprintf('%5.3f seconds', obj.runtime)} command #{c.bold { obj.failure? ? c.red('failed') : c.green('successful') }}.\n"
      end
    else
      original_output << c.black(c.on_yellow("Output formatter doesn't know how to handle #{obj.inspect}\n"))
    end
  end
  private
  def c
    @c ||= Term::ANSIColor
  end
end

Deploy.config.output = ColorizedFormatter.new($stdout)

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
