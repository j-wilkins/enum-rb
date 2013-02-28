require "bundler/gem_tasks"
require 'rake/testtask'

Rake::TestTask.new do |t|
  t.libs << File.join(File.dirname(__FILE__), 'lib')
  t.test_files = FileList['test/**/test*.rb']
  t.verbose = true
end
