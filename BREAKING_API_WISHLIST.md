# Breaking API Wishlist

SSHKit respects semantic versioning. This file is a place to record breaking API improvements
which could be considered at the next major release.

* Consider no longer stripping by default on `capture` [#249](https://github.com/capistrano/sshkit/pull/249)

## Deprecated code which could be deleted in a future major release

* [Abstract.background method](lib/sshkit/backends/abstract.rb#L43)
* [`@stderr`, `@stdout` attrs on `Command`](lib/sshkit/command.rb#L28)

## Cleanup when Ruby 1.9 support is dropped
* `to_a` can probably be removed from `"str".lines.to_a`, since `"str".lines` returns an `Array` under Ruby 2