## Changelog

This file is written in reverse chronological order, newer releases will
appear at the top.

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
