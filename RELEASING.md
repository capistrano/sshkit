# Releasing

## Prerequisites

* You must have commit rights to the SSHKit repository.
* You must have push rights for the sshkit gem on rubygems.org.
* You must be using Ruby >= 2.5.0.

## How to release

1. Run `bundle install` to make sure that you have all the gems necessary for testing and releasing.
2.  **Ensure the tests are passing by running `rake test`.** If functional tests fail, ensure you have [Docker installed](https://docs.docker.com/get-docker/) and running.
3. Determine which would be the correct next version number according to [semver](http://semver.org/).
4. Update the version in `./lib/sshkit/version.rb`.
5. Commit the `version.rb` change with a message like "Preparing vX.Y.Z"
6. Run `rake release`; this will tag, push to GitHub, and publish to rubygems.org
7. Update the draft release on the [GitHub releases page](https://github.com/capistrano/sshkit/releases) to point to the new tag and publish the release
