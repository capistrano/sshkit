## Changelog

This file is written in reverse chronological order, newer releases will
appear at the top.

## 0.0.11

 * Implementing confuguration objects on the backends (WIP, undocumented)
 * Implement `SSHKit.config.default_env`, a hash which can be modified and
   will act as a global `with`.
 * Fixed #9 (with(a: 'b', c: 'c') being parsed as `A=bC=d`. Now properly space
   separated.
 * Fixed #10 (overly aggressive shell escaping), one can now do:
   `with(path: 'foo:$PATH') without the $ being escaped too early.

## 0.0.10

* Include more attributes in `Command#to_hash`.

## 0.0.9

* Include more attributes in `Command#to_hash`.

## 0.0.8

* Added DSL method `background()` this sends a task to the background using
  `nohup` and redirects it's output to `/dev/null` so as to avoid littering
  the filesystem with `nohup.out` files.

**Note:** Backgrounding a task won't work as you expect if you give it a
string, that is you must do `background(:sleep, 5)` and not `background("sleep 5")`
according to the rules by which a command is not processed in any way **if it
contains a spaca character in it's first argument**.

Usage Example:

    on hosts do
      background :rake, "assets:precompile" # typically takes 5 minutes!
    end

**Further:** Many programs are badly behaved and no not work well with `nohup`
it has to do with the way nohup works, reopening the processe's file
descriptors and redirecting them. Programs that re-open, or otherwise
manipulate their own file descriptors may lock up when the SSH session is
disconnected, often they block writing to, or reading from stdin/out.

## 0.0.7

* DSL method `execute()` will now raise `SSHKit::Command::Failed` when the
  exit status is non-zero. The message of the exception will be whatever the
  process had written to stdout.
* New DSL method `test()` behaves as `execute()` used to until this version.
* `Command` now raises an error in `#exit_status=()` if the exit status given
  is not zero. (see below)
* All errors raised by error conditions of SSHKit are defined as subclasses of
  `SSHKit::StandardError` which is itself a subclass of `StandardError`.

The `Command` objects can be set to not raise, by passing `raise_on_non_zero_exit: false`
when instantiating them, this is exactly what `test()` does internally.

Example:

    on hosts do |host
      if test "[ -d /opt/sites ]" do
        within "/opt/sites" do
          execute :git, :pull
        end
      else
        execute :git, :clone, 'some-repository', '/opt/sites'
      end
    end

## 0.0.6

* Support arbitrary properties on Host objects. (see below)

Starting with this version, the `Host` class supports arbitrary properties,
here's a proposed use-case:

    servers = %w{one.example.com two.example.com
                 three.example.com four.example.com}.collect do |s|
      h = SSHKit::Host.new(s)
      if s.match /(one|two)/
        h.properties.roles = [:web]
      else
        h.properties.roles = [:app]
      end
    end

    on servers do |host|
      if host.properties.roles.include?(:web)
        # Do something pertinent to web servers
      elsif host.properties.roles.include?(:app)
        # Do something pertinent to application servers
      end
    end

Naturally, this is a contrived example, the `#properties` attribute on the
Host instance is implemented as an [`OpenStruct`](http://ruby-doc.org/stdlib-1.9.3/libdoc/ostruct/rdoc/OpenStruct.html) and
will behave exactly as such.

## 0.0.5

* Removed configuration option `SSHKit.config.format` (see below)
* Removed configuration option `SSHKit.config.runner` (see below)

The format should now be set by doing:

    SSHKit.config.output = File.open('/dev/null')
    SSHKit.config.output = MyFormatterClass.new($stdout)

The library ships with three formatters, `BlackHole`, `Dot` and `Pretty`.

The default is `Pretty`, but can easily be changed:

    SSHKit.config.output = SSHKit::Formatter::Pretty.new($stdout)
    SSHKit.config.output = SSHKit::Formatter::Dot.new($stdout)
    SSHKit.config.output = SSHKit::Formatter::BlackHole.new($stdout)

The one and only argument to the formatter is the *String/StringIO*ish object
to which the output should be sent. (It should be possible to stack
formatters, or build a multi-formatter to log, and stream to the screen, for
example)

The *runner* is now set by `default_options` on the Coordinator class. The
default is still *:parallel*, and can be overridden on the `on()` (or
`Coordinator#each`) calls directly.

There is no global way to change the runner style for all `on()` calls as of
version `0.0.5`.

## 0.0.4

* Rename the ConnectionManager class to Coordinator, connections are handled
  in the backend, if it needs to create some connections.

## 0.0.3

* Refactor the runner classes into an abstract heirarchy.

## 0.0.2

* Include a *Pretty* formatter
* Modify example to use Pretty formatter.
* Move common behaviour to an abstract formatter.
* Formatters no longer inherit StringIO

## 0.0.1

First release.
