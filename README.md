![SSHKit Logo](https://raw.github.com/leehambley/sshkit/master/assets/images/logo.png)

**SSHKit** is a toolkit for running commands in a structured way on one or
more servers.

[![Build Status](https://travis-ci.org/capistrano/sshkit.png?branch=master)](https://travis-ci.org/capistrano/sshkit)
[![Dependency Status](https://gemnasium.com/leehambley/sshkit.png)](https://gemnasium.com/leehambley/sshkit)

## How might it work?

The typical use-case looks something like this:

```ruby
require 'sshkit/dsl'

on %w{1.example.com 2.example.com}, in: :sequence, wait: 5 do
  within "/opt/sites/example.com" do
    as :deploy  do
      with rails_env: :production do
        rake   "assets:precompile"
        runner "S3::Sync.notify"
        execute "node", "socket_server.js"
      end
    end
  end
end
```

One will notice that it's quite low level, but exposes a convenient API, the
`as()`/`within()`/`with()` are nestable in any order, repeatable, and stackable.

When used inside a block in this way, `as()` and `within()` will guard
the block they are given with a check.

In the case of `within()`, an error-raising check will be made that the directory
exists; for `as()` a simple call to `sudo su -<user> whoami` wrapped in a check for
success, raising an error if unsuccessful.

The directory check is implemented like this:

    if test ! -d <directory>; then echo "Directory doesn't exist" 2>&1; false; fi

And the user switching test implemented like this:

    if ! sudo su <user> -c whoami > /dev/null; then echo "Can't switch user" 2>&1; false; fi

According to the defaults, any command that exits with a status other than 0
raises an error (this can be changed). The body of the message is whatever was
written to *stdout* by the process. The `1>&2` redirects the standard output
of echo to the standard error channel, so that it's available as the body of
the raised error.

Helpers such as `runner()` and `rake()` which expand to `execute(:rails, "runner", ...)` and
`execute(:rake, ...)` are convenience helpers for Ruby, and Rails based apps.

## Parallel

Notice on the `on()` call the `in: :sequence` option, the following will do
what you might expect:

```ruby
on(in: :parallel) { ... }
on(in: :sequence, wait: 5) { ... }
on(in: :groups, limit: 2, wait: 5) { ... }
```

The default is to run `in: :parallel` which has no limit. If you have 400 servers,
this might be a problem and you might better look at changing that to run in
`groups`, or `sequence`.

Groups were designed in this case to relieve problems (mass Git checkouts)
where you rely on a contested resource that you don't want to DDOS by hitting
it too hard.

Sequential runs were intended to be used for rolling restarts, amongst other
similar use-cases.

## Synchronisation

The `on()` block is the unit of synchronisation, one `on()` block will wait
for all servers to complete before it returns.

For example:

```ruby
all_servers = %w{one.example.com two.example.com three.example.com}
site_dir    = '/opt/sites/example.com'

# Let's simulate a backup task, assuming that some servers take longer
# then others to complete
on all_servers do |host|
  in site_dir do
    execute :tar, '-czf', "backup-#{host.hostname}.tar.gz", 'current'
    # Will run: "/usr/bin/env tar -czf backup-one.example.com.tar.gz current"
  end
end

# Now we can do something with those backups, safe in the knowledge that
# they will all exist (all tar commands exited with a success status, or
# that we will have raised an exception if one of them failed.
on all_servers do |host|
  in site_dir do
    backup_filename = "backup-#{host.hostname}.tar.gz"
    target_filename = "backups/#{Time.now.utc.iso8601}/#{host.hostname}.tar.gz"
    puts capture(:s3cmd, 'put', backup_filename, target_filename)
  end
end
```

## The Command Map

It's often a problem that programmatic SSH sessions don't have the same environment
variables as interactive sessions.

A problem often arises when calling out to executables expected to be on
the `$PATH`.  Under conditions without dotfiles or other environmental
configuration, `$PATH` may not be set as expected, and thus executables are not found where expected.

To try and solve this there is the `with()` helper which takes a hash of variables and makes them
available to the environment.

```ruby
with path: '/usr/local/bin/rbenv/shims:$PATH' do
  execute :ruby, '--version'
end
```

Will execute:

    ( PATH=/usr/local/bin/rbenv/shims:$PATH /usr/bin/env ruby --version )

By contrast, the following won't modify the command at all:


```ruby
with path: '/usr/local/bin/rbenv/shims:$PATH' do
  execute 'ruby --version'
end
```

Will execute, without mapping the environmental variables, or querying the command map:

    ruby --version

(This behaviour is sometimes considered confusing, but it has mostly to do with shell escaping: in the case of whitespace in your command, or newlines, we have no way of reliably composing a correct shell command from the input given.)

**Often more preferable is to use the *command map*.**

The *command map* is used by default when instantiating a *Command* object

The *command map* exists on the configuration object, and in principle is
quite simple, it's a *Hash* structure with a default key factory block
specified, for example:

```ruby
puts SSHKit.config.command_map[:ruby]
# => /usr/bin/env ruby
```

To make clear the environment is being deferred to, the `/usr/bin/env` prefix is applied to all commands.
Although this is what happens anyway when one would simply attempt to execute `ruby`, making it
explicit hopefully leads people to explore the documentation.

One can override the hash map for individual commands:

```ruby
SSHKit.config.command_map[:rake] = "/usr/local/rbenv/shims/rake"
puts SSHKit.config.command_map[:rake]
# => /usr/local/rbenv/shims/rake
```

Another opportunity is to add command prefixes:

```ruby
SSHKit.config.command_map.prefix[:rake].push("bundle exec")
puts SSHKit.config.command_map[:rake]
# => bundle exec rake

SSHKit.config.command_map.prefix[:rake].unshift("/usr/local/rbenv/bin exec")
puts SSHKit.config.command_map[:rake]
# => /usr/local/rbenv/bin exec bundle exec rake
```

One can also override the command map completely, this may not be wise, but it
would be possible, for example:

```ruby
SSHKit.config.command_map = Hash.new do |hash, command|
  hash[command] = "/usr/local/rbenv/shims/#{command}"
end
```

This would effectively make it impossible to call any commands which didn't
provide an executable in that directory, but in some cases that might be
desirable.

*Note:* All keys should be symbolised, as the *Command* object will symbolize it's
first argument before attempting to find it in the *command map*.

## Output Handling

![Example Output](https://raw.github.com/leehambley/sshkit/master/assets/images/example_output.png)

By default, the output format is set to `:pretty`: 

```ruby
SSHKit.config.format = :pretty
```

However, if you prefer minimal output, `:dot` format will simply output red or green dots based on the success or failure of operations. 

To output directly to $stdout without any formatting, you can use: 

```ruby
SSHKit.config.output = $stdout
```

## Output Verbosity

By default calls to `capture()` and `test()` are not logged, they are used
*so* frequently by backend tasks to check environmental settings that it
produces a large amount of noise. They are tagged with a verbosity option on
the `Command` instances of `Logger::DEBUG`. The default configuration for
output verbosity is available to override with `SSHKit.config.output_verbosity=`,
and defaults to `Logger::INFO`.

At present the `Logger::WARN`, `ERROR` and `FATAL` are not used.

## Connection Pooling

SSHKit uses a simple connection pool (enabled by default) to reduce the
cost of negotiating a new SSH connection for every `on()` block. Depending on
usage and network conditions, this can add up to a significant time savings.
In one test, a basic `cap deploy` ran 15-20 seconds faster thanks to the
connection pooling added in recent versions of SSHKit.

To prevent connections from "going stale", an existing pooled connection will
be replaced with a new connection if it hasn't been used for more than 30
seconds. This timeout can be changed as follows:

```ruby
SSHKit::Backend::Netssh.pool.idle_timeout = 60 # seconds
```

If you suspect the connection pooling is causing problems, you can disable the
pooling behaviour entirely by setting the idle_timeout to zero:

```ruby
SSHKit::Backend::Netssh.pool.idle_timeout = 0 # disabled
```

## Known Issues

* No handling of slow / timed out connections
* No handling of slow / hung remote commands
* ~~No built-in way to background() something (execute and background the
  process).~~
* No environment handling (sshkit might not need to care)
* ~~No arbitrary `Host` properties (example storing `roles` on servers, or other
  metadata that might be useful in the `on()` block)~~
* ~~No log/warning facility (passing Log messages to the output would work)
  A log object could be made available globally which would emit a LogMessage
  type object which would be recognised by the formatters that need to care
  about them.~~
* ~~No verbosity control, commands should have a `Logger::LEVEL` on them,
  user-generated should be at a high level, the commands auto-generated from
  the guards and checks from as() and within() should have a lower level.~~
* ~~Decide if `execute()` (and friends) should raise on non-zero exit statuses or
  not, perhaps a family of similarly named bang methods should be the ones to
  raise. (Perhaps `test()` should be a way to `execute()` without raising, and
  `execute()` and friends should always raise)~~
* ~~It would be nice to be able to say `SSHKit.config.formatter = :pretty` and
  have that method setter do the legwork of updating `SSHKit.config.output` to
  be an instance of the correct formatter class wrapping the existing output
  stream.~~
* No "trace" level debugging for internal stuff, the debug level should be
  reserved for client-level debugging, with trace being (int -1) used
  internally for logging about connection opening, closing, timing out, etc.
* No method for uploading or downloading files, or the same for saving/loading
  a string to/from a remote file.
* No closing of connections, the abstract backend class should include a
  cleanup method which is empty but can be overridden by other implementations.
* ~~No connection pooling, the `connection` method of the NetSSH backend could
  easily be modified to look into some connection factory for it's objects,
  saving half a second when running lots of `on()` blocks.~~
* Documentation! (YARD style)
* Wrap all commands in a known shell, that is that `execute('uptime')` should
  be converted into `sh -c 'uptime'` to ensure that we have a consistent shell
  experience.
* ~~There's no suitable host parser that accepts `Host.new('user@ip:port')`, it
  will decode a `user@hostname:port`, but IP addresses don't work.~~
* If Net::SSH raises `IOError` (as it does when authentication fails) this
  needs to be caught, and re-raised as some kind of ConnectionFailed error.
