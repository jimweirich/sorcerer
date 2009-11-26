#!/usr/bin/env ruby

# Modify the TestTask to allow running ruby19 for the tests
class Ruby19TestTask < Rake::TestTask
  def ruby(*args)
    sh "#{RUBY} #{args.join(' ')}"
  end
end

Ruby19TestTask.new(:test) do |t|
  t.warning = true
  t.verbose = false
  t.test_files = FileList["test/#{PROJ}/*_test.rb"]
end

