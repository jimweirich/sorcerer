#!/usr/bin/env ruby"

require 'rake/clean'

task :default => :test

Rake::TestTask.new(:test) do |t|
  t.warnings = true
  t.verbose = false
  t.test_files = FileList['*_test.rb']
end
