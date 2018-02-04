## Changelog

This file is written in reverse chronological order, newer releases will
appear at the top.

## [Unreleased][]

  * Your contribution here!

## [1.16.0][] (2018-02-03)

  * [#417](https://github.com/capistrano/sshkit/pull/417): Cache key generation for connections becomes slow when `known_hosts` is a valid `net/ssh` options and `known_hosts` file is big. This changes the cache key generation and fixes performance issue - [@ElvinEfendi](https://github.com/ElvinEfendi).

## [1.15.1][] (2017-11-18)

This is a small bug-fix release that fixes problems with `upload!` and `download!` that were inadvertently introduced in 1.15.0.

### Breaking changes

  * None

### Bug fixes

  * [#410](https://github.com/capistrano/sshkit/pull/410): fix NoMethodError when using upload!/download! with Pathnames - [@UnderpantsGnome](https://github.com/UnderpantsGnome)
  * [#411](https://github.com/capistrano/sshkit/pull/410): fix upload!/download! when using relative paths outside of `within` blocks -  [@Fjan](https://github.com/Fjan)

## [1.15.0][] (2017-11-03)

### New features

  * [#408](https://github.com/capistrano/sshkit/pull/408): upload! and download! now respect `within` - [@sj26](https://github.com/sj26)

### Potentially breaking changes

  * `upload!` and `download!` now support remote paths which are
    relative to the `within` working directory. They were previously documented
    as only supporting absolute paths, but relative paths still worked relative
    to the remote working directory. If you rely on the previous behaviour you
    may need to adjust your code.

## [1.14.0][] (2017-06-30)

### Breaking changes

  * None

### New features

  * [#401](https://github.com/capistrano/sshkit/pull/401): Add :log_percent option to specify upload!/download! transfer log percentage - [@aubergene](https://github.com/aubergene)

## [1.13.1][] (2017-03-31)

### Breaking changes

  * None

### Bug fixes

  * [#397](https://github.com/capistrano/sshkit/pull/397): Fix NoMethodError assign_defaults with net-ssh older than 4.0.0 - [@shirosaki](https://github.com/shirosaki)

## [1.13.0][] (2017-03-24)

### Breaking changes

  * None

### New features

  * [#372](https://github.com/capistrano/sshkit/pull/372): Use cp_r in local backend with recursive option - [@okuramasafumi](https://github.com/okuramasafumi)

### Bug fixes

  * [#390](https://github.com/capistrano/sshkit/pull/390): Properly wrap Ruby StandardError w/ add'l context - [@mattbrictson](https://github.com/mattbrictson)
  * [#392](https://github.com/capistrano/sshkit/pull/392): Fix open two connections with changed cache key - [@shirosaki](https://github.com/shirosaki)

## [1.12.0][] (2017-02-10)

### Breaking changes

  * None

### New features

  * Add `SSHKit.config.default_runner_config` option that allows overriding default runner configs.

## [1.11.5][] (2016-12-16)

### Bug fixes

  * Do not prefix `exec` command
    [PR #378](https://github.com/capistrano/sshkit/pull/378) @dreyks

## [1.11.4][] (2016-11-02)

  * Use string interpolation for environment variables to avoid escaping issues
    with sprintf
    [PR #280](https://github.com/capistrano/sshkit/pull/280)
    @Sinjo - Chris Sinjakli

## [1.11.3][] (2016-09-16)

  * Fix known_hosts caching to match on the entire hostlist
    [PR #364](https://github.com/capistrano/sshkit/pull/364) @byroot

## [1.11.2][] (2016-07-29)

### Bug fixes

  * Fixed a crash occurring when `Host@keys` was set to a non-Enumerable.
    @xavierholt [PR #360](https://github.com/capistrano/sshkit/pull/360)

## [1.11.1][] (2016-06-17)

### Bug fixes

  * Fixed a regression in 1.11.0 that would cause
    `ArgumentError: invalid option(s): known_hosts` in some older versions of
    net-ssh. @byroot [#357](https://github.com/capistrano/sshkit/issues/357)

## [1.11.0][] (2016-06-14)

### Bug fixes

  * Fixed colorized output alignment in Logger::Pretty. @xavierholt
    [PR #349](https://github.com/capistrano/sshkit/pull/349)
  * Fixed a bug that prevented nested `with` calls
    [#43](https://github.com/capistrano/sshkit/issues/43)

### Other changes

  * Known hosts lookup optimization is now enabled by default. @byroot

## 1.10.0 (2016-04-22)

  * You can now opt-in to caching of SSH's known_hosts file for a speed boost
    when deploying to a large fleet of servers. Refer to the
    [README](https://github.com/capistrano/sshkit/tree/v1.10.0#known-hosts-caching) for
    details. We plan to turn this on by default in a future version of SSHKit.
    [PR #330](https://github.com/capistrano/sshkit/pull/330) @byroot
  * SSHKit now explicitly closes its pooled SSH connections when Ruby exits;
    this fixes `zlib(finalizer): the stream was freed prematurely` warnings
    [PR #343](https://github.com/capistrano/sshkit/pull/343) @mattbrictson
  * Allow command map entries (`SSHKit::CommandMap#[]`) to be Procs
    [PR #310](https://github.com/capistrano/sshkit/pull/310)
    @mikz

## 1.9.0

**Refer to the 1.9.0.rc1 release notes for a full list of new features, fixes,
and potentially breaking changes since SSHKit 1.8.1.** There are no changes
since 1.9.0.rc1.

## 1.9.0.rc1

### Potentially breaking changes

  * The SSHKit DSL is no longer automatically included when you `require` it.
    **This means you  must now explicitly `include SSHKit::DSL`.**
    See [PR #219](https://github.com/capistrano/sshkit/pull/219) for details.
    @beatrichartz
  * `SSHKit::Backend::Printer#test` now always returns true
    [PR #312](https://github.com/capistrano/sshkit/pull/312) @mikz

### New features

  * `SSHKit::Formatter::Abstract` now accepts an optional Hash of options
    [PR #308](https://github.com/capistrano/sshkit/pull/308) @mattbrictson
  * Add `SSHKit::Backend.current` so that Capistrano plugin authors can refactor
    helper methods and still have easy access to the currently-executing Backend
    without having to use global variables.
  * Add `SSHKit.config.default_runner` options that allows to override default command runner.
    This option also accepts a name of the custom runner class.
  * The ConnectionPool has been rewritten in this release to be more efficient
    and have a cleaner internal API. You can still completely disable the pool
    by setting `SSHKit::Backend::Netssh.pool.idle_timeout = 0`.
    @mattbrictson @byroot [PR #328](https://github.com/capistrano/sshkit/pull/328)

### Bug fixes

  * make sure working directory for commands is properly cleared after `within` blocks
    [PR #307](https://github.com/capistrano/sshkit/pull/307)
    @steved
  * display more accurate string for commands with spaces being output in `Formatter::Pretty`
    [PR #304](https://github.com/capistrano/sshkit/pull/304)
    @steved
    [PR #319](https://github.com/capistrano/sshkit/pull/319) @mattbrictson
  * Fix a race condition experienced in JRuby that could cause multi-server
    deploys to fail. [PR #322](https://github.com/capistrano/sshkit/pull/322)
    @mattbrictson

## 1.8.1

  * Change license to MIT, thanks to all the patient contributors who gave
    their permissions.

## 1.8.0

  * add SSHKit::Backend::ConnectionPool#close_connections
    [PR #285](https://github.com/capistrano/sshkit/pull/285)
    @akm
  * Clean up rubocop lint warnings
    [PR #275](https://github.com/capistrano/sshkit/pull/275)
    @cshaffer
    * Prepend unused parameter names with an underscore
    * Prefer “safe assignment in condition”
    * Disambiguate regexp literals with parens
    * Prefer `sprintf` over `String#%`
    * No longer shadow `caller_line` variable in `DeprecationLogger`
    * Rescue `StandardError` instead of `Exception`
    * Remove useless `private` access modifier in `TestAbstract`
    * Disambiguate block operator with parens
    * Disambiguate between grouped expression and method params
    * Remove assertion in `TestHost#test_assert_hosts_compare_equal` that compares something with itself
  * Export environment variables and execute command in a subshell.
    [PR #273](https://github.com/capistrano/sshkit/pull/273)
    @kuon
  * Introduce `log_command_start`, `log_command_data`, `log_command_exit` methods on `Formatter`
    [PR #257](https://github.com/capistrano/sshkit/pull/257)
    @robd
    * Deprecate `@stdout` and `@stderr` accessors on `Command`
  * Add support for deprecation logging options.
    [README](README.md#deprecation-warnings),
    [PR #258](https://github.com/capistrano/sshkit/pull/258)
    @robd
  * Quote environment variable values.
    [PR #250](https://github.com/capistrano/sshkit/pull/250)
    @Sinjo - Chris Sinjakli
  * Simplified formatter hierarchy.
    [PR #248](https://github.com/capistrano/sshkit/pull/248)
    @robd
    * `SimpleText` formatter now extends `Pretty`, rather than duplicating.
  * Hide ANSI color escape sequences when outputting to a file.
    [README](README.md#output-colors),
    [Issue #245](https://github.com/capistrano/sshkit/issues/245),
    [PR #246](https://github.com/capistrano/sshkit/pull/246)
    @robd
    * Now only color the output if it is associated with a tty,
      or the `SSHKIT_COLOR` environment variable is set.
  * Removed broken support for assigning an `IO` to the `output` config option.
    [Issue #243](https://github.com/capistrano/sshkit/issues/243),
    [PR #244](https://github.com/capistrano/sshkit/pull/244)
    @robd
    * Use `SSHKit.config.output = SSHKit::Formatter::SimpleText.new($stdin)` instead
  * Added support for `:interaction_handler` option on commands.
    [PR #234](https://github.com/capistrano/sshkit/pull/234),
    [PR #242](https://github.com/capistrano/sshkit/pull/242)
    @robd
  * Removed partially supported `TRACE` log level.
    [2aa7890](https://github.com/capistrano/sshkit/commit/2aa78905f0c521ad9f697e7a4ed04ba438d5ee78)
    @robd
  * Add support for the `:strip` option to the `capture` method and strip by default on the `Local` backend.
    [PR #239](https://github.com/capistrano/sshkit/pull/239),
    [PR #249](https://github.com/capistrano/sshkit/pull/249)
    @robd
    * The `Local` backend now strips by default to be consistent with the `Netssh` one.
    * This reverses change [7d15a9a](https://github.com/capistrano/sshkit/commit/7d15a9aebfcc43807c8151bf6f3a4bc038ce6218) to the `Local` capture API to remove stripping by default.
    * If you require the raw, unstripped output, pass the `strip: false` option: `capture(:ls, strip: false)`
  * Simplified backend hierarchy.
    [PR #235](https://github.com/capistrano/sshkit/pull/235),
    [PR #237](https://github.com/capistrano/sshkit/pull/237)
    @robd
    * Moved duplicate implementations of `make`, `rake`, `test`, `capture`, `background` on to `Abstract` backend.
    * Backend implementations now only need to implement `execute_command`, `upload!` and `download!`
    * Removed `Printer` from backend hierarchy for `Local` and `Netssh` backends (they now just extend `Abstract`)
    * Removed unused `Net::SSH:LogLevelShim`
  * Removed dependency on the `colorize` gem. SSHKit now implements its own ANSI color logic, with no external dependencies. Note that SSHKit now only supports the `:bold` or plain modes. Other modes will be gracefully ignored. [#263](https://github.com/capistrano/sshkit/issues/263)
  * New API for setting the formatter: `use_format`. This differs from `format=` in that it accepts options or arguments that will be passed to the formatter's constructor. The `format=` syntax will be deprecated in a future release. [#295](https://github.com/capistrano/sshkit/issues/295)
  * SSHKit now immediately raises a `NameError` if you try to set a formatter that does not exist. [#295](https://github.com/capistrano/sshkit/issues/295)
  * Fix error message when the formatter does not exist. [#301](https://github.com/capistrano/sshkit/pull/301)

## 1.7.1

  * Fix a regression in 1.7.0 that caused command completion messages to be removed from log output. @mattbrictson

## 1.7.0

  * Update Vagrantfile to use multi-provider Hashicorp precise64 box - remove URLs. @townsen
  * Merge host ssh_options and Netssh defaults @townsen
    Previously if host-level ssh_options were defined the Netssh defaults
    were ignored.
  * Merge host ssh_options and Netssh defaults
  * Fixed race condition where output of failed command would be empty. @townsen
    Caused random failures of `test_execute_raises_on_non_zero_exit_status_and_captures_stdout_and_stderr`
    Also fixes output handling in failed commands, and generally buggy output.
  * Remove override of backtrace() and backtrace_locations() from ExecuteError. @townsen
    This interferes with rake default behaviour and creates duplicate stacktraces.
  * Allow running local commands using `on(:local)`
  * Implement the upload! and download! methods for the local backend

## 1.6.0

  * Fix colorize to use the correct API (@fazibear)
  * Lock colorize (sorry guys) version at >= 0.7.0

## 1.6.0 (Yanked, because of colorize.)

  * Force dependency on colorize v0.6.0
  * Add your entries here, remember to credit yourself however you want to be
    credited!
  * Remove strip from capture to preserve whitespace. Nick Townsend
  * Add vmware_fusion Vagrant provider. Nick Townsend
  * Add some padding to the pretty log formatter

## 1.5.1

  * Use `sudo -u` rather than `sudo su` to switch users. Mat Trudel

## 1.5.0

  * Deprecate background helper - too many badly behaved pseudo-daemons. Lee Hambley
  * Don't colourize unless $stdout is a tty. Lee Hambley
  * Remove out of date "Known Issues" section from README. Lee Hambley
  * Dealy variable interpolation inside `as()` block. Nick Townsend
  * Fixes for functional tests under modern Vagrant. Lewis Marshal
  * Fixes for connection pooling. Chris Heald
  * Add `localhost` hostname to local backend. Adam Mckaig
  * Wrap execptions to include hostname. Brecht Hoflack
  * Remove `shellwords` stdlib dependency Bruno Sutic
  * Remove unused `cooldown` accessor. Bruno Sutic
  * Replace Term::ANSIColor with a lighter solution. Tom Clements
  * Documentation fixes. Matt Brictson

## 1.4.0

https://github.com/capistrano/sshkit/compare/v1.3.0...v1.4.0

  * Removed `invoke` alias for [`SSHKit::Backend::Printer.execute`](https://github.com/capistrano/sshkit/blob/master/lib/sshkit/backends/printer.rb#L20). This is to prevent collisions with
  methods in capistrano with similar names, and to provide a cleaner API. See [capistrano issue 912](https://github.com/capistrano/capistrano/issues/912) and [issue 107](https://github.com/capistrano/sshkit/issues/107) for more details.
  * Connection pooling now uses a thread local to store connection pool, giving each thread its own connection pool. Thank you @mbrictson see [#101](https://github.com/capistrano/sshkit/pull/101) for more.
  * Command map indifferent towards strings and symbols thanks to @thomasfedb see [#91](https://github.com/capistrano/sshkit/pull/91)
  * Moved vagrant wrapper to `support` directory, added ability to run tests with vagrant using ssh. @miry see [#64](https://github.com/capistrano/sshkit/pull/64)
  * Removed unnecessary require `require_relative '../sshkit'` in `lib/sshkit/dsl.rb` prevents warnings thanks @brabic.
  * Doc fixes thanks @seanhandley @vojto

## 1.3.0

https://github.com/capistrano/sshkit/compare/v1.2.0...v1.3.0

  * Connection pooling. SSH connections are reused across multiple invocations
    of `on()`, which can result in significant performance gains. See:
    https://github.com/capistrano/sshkit/pull/70. Matt @mbrictson Brictson.
  * Fixes to the Formatter::Dot and to the formatter class name resolver. @hab287:w
  * Added the license to the Gemspec. @anatol.
  * Fix :limit handling for the `in: :groups` run mode. Phil @phs Smith
  * Doc fixes @seanhandley, @sergey-alekseev.

## 1.2.0

https://github.com/capistrano/sshkit/compare/v1.1.0...v1.2.0

  * Support picking up a project local SSH config file, if a SSH config file
    exists at ./.ssh/config it will be merged with the ~/.ssh/config. This is
    ideal for defining project-local proxies/gateways, etc. Thanks to Alex
    @0rca Vzorov.
  * Tests and general improvements to the Printer backends (mostly used
    internally). Thanks to Michael @miry Nikitochkin.
  * Update the net-scp dependency version. Thanks again to Michael @miry
    Nikitochkin.
  * Improved command map. This feature allows mapped variables to be pushed
    and unshifted onto the mapping so that the Capistrano extensions for
    rbenv and bundler, etc can work together. For discussion about the reasoning
    see https://github.com/capistrano/capistrano/issues/639 and
    https://github.com/capistrano/sshkit/pull/45. A big thanks to Kir @kirs
    Shatrov.
  * `test()` and `capture()` now behave as expected inside a `run_locally` block
    meaning that they now run on your local machine, rather than erring out. Thanks
    to Kentaro @kentaroi Imai.
  * The `:wait` option is now successfully passed to the runner now. Previously the
    `:wait` option was ignored. Thanks to Jordan @jhollinger Hollinger for catching
    the mistake in our test coverage.
  * Fixes and general improvements to the `download()` method which until now was
    quite naïve. Thanks to @chqr.

## 1.1.0

https://github.com/capistrano/sshkit/compare/v1.0.0...v1.1.0

  * Please see the Git history. `git rebase` ate our changelog (we should have been
    more careful)

## 1.0.0

  * The gem now supports a run_locally, although it's nothing to do with SSH,
    it makes a nice API. There are examples in the EXAMPLES.md.

## 0.0.34

  * Allow the setting of global SSH options on the `backend.ssh` as a hash,
    these options are the same as Net::SSH configure expects. Thanks to Rafał
    @lisukorin Lisowski

## 0.0.32

  * Lots of small changes since 0.0.27.
  * Particularly working around a possible NaN issue when uploading
    comparatively large files.

## 0.0.27

  * Don't clobber SSH options with empty values. This allows Net::SSH to
    do the right thing most of the time, and look into the SSH configuration
    files.

## 0.0.26

  * Pretty output no longer prints white text. ("Command.....")
  * Fixed a double-output bug, where upon receiving the exit status from a
    remote command, the last data packet that it sent would be re-printed
    by the pretty formatter.
  * Integration tests now use an Ubuntu Precise 64 Vagrant base box.
  * Additional host declaration syntax, `SSHKit::Host` can now take a hash of
    host properties in addition to a number of new (common sense) DSN type
    syntaxes.
  * Changes to the constants used for logging, we no longer re-define a
    `Logger::TRACE` constant on the global `Logger` class, rather everyhing
    now uses `SSHKit::Logger` (Thanks to Rafa Garcia)
  * Various syntax and documentation fixes.

## 0.0.25

  * `upload!` and `download!` now log to different levels depending on
    completion percentage. When the upload is 0 percent complete or a number
    indivisible by 10, the message is logged to `Logger::DEBUG` otherwise the
    message is logged to `Logger::INFO`, this should mean that normal users at
    a sane log level should see upload progress jump to `100%` for small
    files, and otherwise for larger files they'll see output every `10%`.

## 0.0.24

  * Pretty output now streams stdout and stderr. Previous versions would
    append (`+=`) chunks of data written by the remote host to the `Command`
    instance, and the `Pretty` formatter would only print stdout/stderr if the
    command was `#complete?`. Historically this lead to issues where the
    remote process was blocking for input, had written the prompt to stdout,
    but it was not visible on the client side.

    Now each time the command is passed to the output stream, the
    stdout/stderr are replaced with the lines returned from the remote server
    in this chunk. (i.e were yielded to the callback block). Commands now have
    attribute accessors for `#full_stdout` and `#full_stderr` which are appended
    in the way that `#stdout` and `#stderr` were previously.

    This should be considered a private API, and one should beware of relying
    on `#full_stdout` or `#full_stderr`, they will likely be replaced with a
    cleaner soltion eventually.

  * `upload!` and `download!` now print progress reports at the `Logger::INFO`
     verbosity level.

## 0.0.23

  * Explicitly rely on `net-scp` gem.

## 0.0.22

  * Added naïve implementations of `upload!()` and `download!()` (syncoronous) to
    the Net::SSH backend. See `EXAMPLES.md` for more extensive usage examples.

    The `upload!()` method can take a filename, or an `IO`, this reflects the way
    the underlying Net::SCP implementation works. The same is true of
    `download!()`, when called with a single argument it captures the file's
    contents, otherwise it downloads the file to the local disk.

        on hosts do |host|
          upload!(StringIO.new('some-data-here'), '~/.ssh/authorized_keys')
          upload!('~/.ssh/id_rsa.pub', '~/.ssh/authorized_keys')
          puts download!('/etc/monit/monitrc')
          download!('/etc/monit/monitrc', '~/monitrc')
        end

## 0.0.21

  * Fixed an issue with default formatter
  * Modified `SSHKit.config.output_verbosity=` to accept different objects:

        SSHKit.config.output_verbosity = Logger::INFO
        SSHKit.config.output_verbosity = :info
        SSHKit.config.output_verbosity = 1

## 0.0.20

 * Fixed a bug where the log level would be assigned, not compared in the
   pretty formatter, breaking the remainder of the output verbosity.

## 0.0.19

 * Modified the `Pretty` formatter to include the log level in front of
   executed commands.

 * Modified the `Pretty` formatter not to print stdout and stderr by default,
   the log level must be raised to Logger::DEBUG to see the command outputs.

 * Modified the `Pretty` formatter to use `Command#to_s` when printing the
   command, this prints the short form (without modifications/wrappers applied
   to the command for users, groups, directories, umasks, etc).

## 0.0.18

 * Enable `as()` to take either a string/symbol as previously, but also now
   accepts a hash of `{user: ..., group: ...}`. In case that your host system
   supports the command `sg` (`man 1 sg`) to switch your effective group ID
   then one can work on files as a team group user.

        on host do |host|
          as user: :peter, group: griffin do
            execute :touch, 'somefile'
          end
        end

    will result in a file with the following permissions:

        -rw-r--r-- 1 peter griffin 0 Jan 27 08:12 somefile

    This should make it much easier to share deploy scripts between team
    members.

    **Note:** `sg` has some very strict user and group password requirements
    (the user may not have a password (`passwd username -l` to lock an account
    that already has a password), and the group may not have a password.)

    Additionally, and unsurprisingly *the user must also be a member of the
    group.*

    `sg` was chosen over `newgrp` as it's easier to embed in a one-liner
    command, `newgrp` could be used with a heredoc, but my research suggested
    that it might be better to use sg, as it better represents my intention, a
    temporary switch to a different effective group.

 * Fixed a bug with environmental variables and umasking introduced in 0.0.14.
   Since that version the environmental variables were being presented to the
   umask command's subshell, and not to intended command's subshell.

       incorrect: `ENV=var umask 002 && env`
       correct:   `umask 002 && ENV=var env`

 * Changed the exception handler, if a command returns with a non-zero exit
   status then the output will be prefixed with the command name and which
   channel any output was written to, for example:

       Command.new("echo ping; false")
       => echo stdout: ping
          echo stderr: Nothing written

   In this contrived example that's more or less useless, however with badly
   behaved commands that write errors to stdout, and don't include their name
   in the program output, it can help a lot with debugging.

## 0.0.17

 * Fixed a bug introduced in 0.0.16 where the capture() helper returned
   the name of the command that had been run, not it's output.

 * Classify the pre-directory switch, and pre-user switch command guards
   as having a DEBUG log level to exclude them from the logs.

## 0.0.16

 * Fixed a bug introduced in 0.0.15 where the capture() helper returned
   boolean, discarding any output from the server.

## 0.0.15

 * `Command` now takes a `verbosity` option. This defaults to `Logger::INFO`
   and can be set to any of the Ruby logger level constants. You can also set
   it to the symbol `:debug` (and friends) which will be expanded into the correct
   constants.

   The log verbosity level is set to Logger::INFO by default, and can be
   overridden by setting `SSHKit.config.output_verbosity = Logger::{...}`,
   pick a level that works for you.

   By default `test()` and `capture()` calls are surpressed, and not printed
   by the pretty logger as of this version.

## 0.0.14

 * Umasks can now be set on `Command` instances. It can be set globally with
   `SSHKit.config.umask` (default, nil; meaning take the system default). This
   can be used to set, for example a umask of `007` for allowing users with
   the same primary group to share code without stepping on eachother's toes.

## 0.0.13

 * Correctly quote `as(user)` commands, previously it would expand to:
   `sudo su user -c /usr/bin/env echo "Hello World"`, in which the command to
   run was taken as simply `/usr/bin/env`. By quoting all arguments it should
   now work as expected. `sudo su user -c "/usr/bin/env echo \""Hello World\""`

## 0.0.12

 * Also print anything the program wrote to stdout when the exit status is
   non-zero and the command raises an error. (assits debugging badly behaved
   programs that fail, and write their error output to stdout.)

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

## 0.0.7

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

## 0.0.2

* Include a *Pretty* formatter
* Modify example to use Pretty formatter.
* Move common behaviour to an abstract formatter.
* Formatters no longer inherit StringIO

## 0.0.1

First release.

[Unreleased]: https://github.com/capistrano/sshkit/compare/v1.16.0...HEAD
[1.16.0]: https://github.com/capistrano/sshkit/compare/v1.15.1...v1.16.0
[1.15.1]: https://github.com/capistrano/sshkit/compare/v1.15.0...v1.15.1
[1.15.0]: https://github.com/capistrano/sshkit/compare/v1.14.0...v1.15.0
[1.14.0]: https://github.com/capistrano/sshkit/compare/v1.13.1...v1.14.0
[1.13.1]: https://github.com/capistrano/sshkit/compare/v1.13.0...v1.13.1
[1.13.0]: https://github.com/capistrano/sshkit/compare/v1.12.0...v1.13.0
[1.12.0]: https://github.com/capistrano/sshkit/compare/v1.11.5...v1.12.0
[1.11.5]: https://github.com/capistrano/sshkit/compare/v1.11.4...v1.11.5
[1.11.4]: https://github.com/capistrano/sshkit/compare/v1.11.3...v1.11.4
[1.11.3]: https://github.com/capistrano/sshkit/compare/v1.11.2...v1.11.3
[1.11.2]: https://github.com/capistrano/sshkit/compare/v1.11.1...v1.11.2
[1.11.1]: https://github.com/capistrano/sshkit/compare/v1.11.0...v1.11.1
[1.11.0]: https://github.com/capistrano/sshkit/compare/v1.10.0...v1.11.0
