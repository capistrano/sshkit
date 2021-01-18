source 'https://rubygems.org'

gemspec

# public_suffix 3+ requires ruby 2.1+
if Gem::Requirement.new('< 2.1').satisfied_by?(Gem::Version.new(RUBY_VERSION))
  gem 'public_suffix', '< 3'
end
