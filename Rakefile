#!/usr/bin/env ruby"

require 'rake/clean'
require 'rake/testtask'

begin
  require 'rubygems'
  require 'rake/gempackagetask'
rescue Exception
  nil
end

PROJ = 'sorcerer'
RUBY = 'ruby19'
PKG_VERSION = '0.0.1'

PKG_FILES = FileList[
  'README.textile',
  'Rakefile',
  'doc/*',
  'rakelib/*',
  'lib/**/*.rb',
  'test/**/*.rb',
]
  
BASE_RDOC_OPTIONS = [
  '--line-numbers', '--inline-source',
  '--main' , 'README.rdoc',
  '--title', 'Rake -- Ruby Make'
]

task :default => :test

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

if ! defined?(Gem)
  puts "Package Target requires RubyGEMs"
else
  SPEC = Gem::Specification.new do |s|
    s.name = 'sorcerer'
    s.version = PKG_VERSION
    s.summary = "Generate Source from Ripper ASTs"
    s.description = <<-EOF
      Generate the original Ruby source from a Ripper-style abstract syntax tree.
    EOF
    s.files = PKG_FILES.to_a
    s.require_path = 'lib'                         # Use these for libraries.
    s.has_rdoc = true
    s.rdoc_options = BASE_RDOC_OPTIONS
    s.author = "Jim Weirich"
    s.email = "jim.weirich@gmail.com"
    s.rubyforge_project = 'sorcerer'
    s.homepage = "http://github.com/jimweirich/sorcerer"
  end

  package_task = Rake::GemPackageTask.new(SPEC) do |pkg|
    pkg.need_zip = true
    pkg.need_tar = true
  end
end
