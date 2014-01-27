## Is it better than Capistrano?

*SSHKit* is designed to solve a different problem than Capistrano. *SSHKit* is
a toolkit for performing structured commands on groups of servers in a
repeatable way.

It provides concurrency handling, sane error checking and control flow that
would otherwise be difficult to achieve with pure *Net::SSH*.

Since *Capistrano v3.0*, *SSHKit* is used by *Capistrano* to communicate with
backend servers. Whilst Capistrano provides the structure for repeatable
deployments.

## Why does <something> stop responding after I started it with `background()`?

The answer is complicated, but it can be summed up by saying that under
certain circumstances processes can find themselves connected to file
descriptors which no longer exist.

The following resources are worth a read to better understand what a process
must do in order to daemonize reliably, not all processes perform all of the
steps necessary:

* [http://stackoverflow.com/questions/881388/what-is-the-reason-for-performing-a-double-fork-when-creating-a-daemon]

This can be summarized as:

> On some flavors of Unix, you are forced to do a double-fork on startup, in order to go into daemon mode. This is because single forking isn’t guaranteed to detach from the controlling terminal.

If you experience consistent problems, please report it as an issue, I'll be
in a position to give a better answer once I can examine the problem in more
detail.

## My daemon doesn't work properly when run from SSHKit

You should probably read:

* http://www.enderunix.org/docs/eng/daemon.php

If any of those things aren't being done by your daemon, then you ought to
adopt some or all of those techniques.
