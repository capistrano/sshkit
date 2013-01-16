## Is it better than Capistrano?

*SSHKit* is designed to solve a different problem than Capistrano. *SSHKit* is
a toolkit for performing structured commands on groups of servers in a
repeatable way.

It provides concurrency handling, sane error checking and control flow that
would otherwise be difficult to achive with pure *Net::SSH*.

Since *Capistrano v3.0*, *SSHKit* is used by *Capistrano* to communicate with
backend servers. Whilst Capistrano provides the structure for repeatable
deployments.

## Production Ready?

It's in private Beta use, and the documentation could use more work, but this
is open source, that's more or less how it works.
