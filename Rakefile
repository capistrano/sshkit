#!/usr/bin/env rake
require 'bundler/gem_tasks'
require 'debugger'
require 'rake/testtask'

namespace :test do

  Rake::TestTask.new(:units) do |t|
    t.libs << 'test'
    t.test_files = FileList['test/unit/**/test*.rb']
  end

  Rake::TestTask.new(:functional) do |t|
    t.libs << 'test'
    t.test_files = FileList['test/functional/**/test*.rb']
  end

  Rake::TestTask.new(:integration) do |t|
    t.libs << 'test'
    t.test_files = FileList['test/integration/**/test*.rb']
  end

  task :test do
    Rake::Task['test:units'].execute
    Rake::Task['test:integration'].execute
    Rake::Task['test:functional'].execute unless ENV['TRAVIS']
  end

  task default: :test

end

task :default => 'test:default'

Rake::Task["test:functional"].enhance do
  warn "Remember there are still some VMs running, kill them with `vagrant halt` if you are finished using them."
end
