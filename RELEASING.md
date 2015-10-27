# Releasing

## Prerequisites

* You must have commit rights to the SSHKit repository.
* You must have push rights for the sshkit gem on rubygems.org.
* You must be using Ruby >= 2.1.0.
* Your `~/.netrc` must be configured with your GitHub credentials, [as explained here](https://github.com/mattbrictson/chandler#2-configure-netrc).

## How to release

1. Run `bundle install` to make sure that you have all the gems necessary for testing and releasing.
2.  **Ensure the tests are passing by running `rake test`.** If functional tests fail, ensure you have [Vagrant](https://www.vagrantup.com) installed and have started it with `vagrant up`.
3. Determine which would be the correct next version number according to [semver](http://semver.org/).
4. Update the version in `./lib/sshkit/version.rb`.
5. Update the `CHANGELOG`.
6. Commit the changelog and version in a single commit, the message should be "Preparing vX.Y.Z"
7. Run `rake release`; this will tag, push to GitHub, publish to rubygems.org, and upload the latest changelog entry to the [GitHub releases page](https://github.com/capistrano/sshkit/releases).
