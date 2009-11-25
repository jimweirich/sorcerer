#!/usr/bin/env ruby"

require 'rake/clean'
require 'rake/testtask'

module Config
  PROJ = 'sorcerer'
  RUBY = 'ruby19'
end

task :default => :test

# Modify the TestTask to allow running ruby19 for the tests
class Ruby19TestTask < Rake::TestTask
  def ruby(*args)
    sh "#{Config::RUBY} #{args.join(' ')}"
  end
end

Ruby19TestTask.new(:test) do |t|
  t.warning = true
  t.verbose = false
  t.test_files = FileList["test/#{Config::PROJ}/*_test.rb"]
end
