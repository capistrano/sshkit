source 'https://rubygems.org'

gemspec

platforms :rbx do
  gem 'rubysl', '~> 2.0'
  gem 'json'
end

# Chandler requires Ruby >= 2.1.0, but depending on the Travis environment,
# we may not meet that requirement. Only include the chandler gem if the Ruby
# requirement is met. (Chandler is used only for `rake release`; see Rakefile.)
if Gem::Requirement.new('>= 2.1.0').satisfied_by?(Gem::Version.new(RUBY_VERSION))
  gem 'chandler', '>= 0.1.1'
end

# public_suffix 3+ requires ruby 2.1+
if Gem::Requirement.new('< 2.1').satisfied_by?(Gem::Version.new(RUBY_VERSION))
  gem 'public_suffix', '< 3'
end

# rbnacl-libsodium > 1.0.15.1 requires Ruby 2.2.6+
if Gem::Requirement.new('< 2.2.6').satisfied_by?(Gem::Version.new(RUBY_VERSION))
  gem 'rbnacl-libsodium', '<= 1.0.15.1'
end
