#!/usr/bin/env ruby


Rake::TestTask.new(:test) do |t|
  t.warning = true
  t.verbose = false
  t.test_files = FileList["test/**/*_test.rb"]
end

