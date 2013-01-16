# Releasing

* **Ensure the tests are passing.**
* Determine which would be the correct next version number according to [semver](http://semver.org/).
* Update the version in `./lib/sshkit/version.rb`.
* Update the `CHANGELOG`.
* Commit the changelog and version in a single commit, the message should be "Preparing vX.Y.Z"
* Tag the commit `git tag vX.Y.Z` (if tagging a historical commit, `git tag` can take a *SHA1* after the tag name)
* Push new commits, and tags to Github.
* Push the gem to [rubygems](http://rubygems.org).
