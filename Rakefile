#!/usr/bin/env ruby"

require 'rake/clean'
require 'rake/testtask'

task :default => :test

Rake::TestTask.new(:test) do |t|
  t.warning = true
  t.verbose = false
  t.test_files = FileList['test/ruby_source/*_test.rb']
end
