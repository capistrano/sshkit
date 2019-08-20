require 'bundler/gem_tasks'
require 'rake/testtask'
require 'rubocop/rake_task'

task :default => [:test, :lint]

desc "Run all tests"
task :test => ['test:units', 'test:functional']

namespace :test do

  Rake::TestTask.new(:units) do |t|
    t.libs << "test"
    t.test_files = FileList['test/unit/**/test*.rb']
  end

  Rake::TestTask.new(:functional) do |t|
    t.libs << "test"
    t.test_files = FileList['test/functional/**/test*.rb']
  end

end

Rake::Task["test:functional"].enhance do
  warn "Remember there are still some VMs running, kill them with `vagrant halt` if you are finished using them."
end

desc 'Run RuboCop lint checks'
RuboCop::RakeTask.new(:lint) do |task|
  task.options = ['--lint']
end

Rake::Task["release"].enhance do
  puts "Don't forget to publish the release on GitHub!"
  system "open https://github.com/capistrano/sshkit/releases"
end
