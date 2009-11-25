#!/usr/bin/env ruby"

require 'rake/clean'
require 'rake/testtask'

module Ruby19
  PROG = 'ruby19'
end

task :default => :test

# Modify the TestTask to allow running ruby19 for the tests
class Ruby19TestTask < Rake::TestTask
  def ruby(*args)
    sh "#{Ruby19::PROG} #{args.join(' ')}"
  end
end

Ruby19TestTask.new(:test) do |t|
  t.warning = true
  t.verbose = false
  t.test_files = FileList['test/ruby_source/*_test.rb']
end
