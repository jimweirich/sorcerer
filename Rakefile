#!/usr/bin/env ruby"

require 'rake/clean'
require 'rake/testtask'
#require 'rdoc/task'

require './lib/sorcerer/version'

begin
  require 'rubygems'
  require 'rubygems/package_task'
rescue Exception
  nil
end

CLEAN.include('pkg/sorcerer-*').exclude('pkg/*.gem')

PROJ = 'sorcerer'
RUBY = ENV['RUBY19'] || 'ruby19'
PKG_VERSION = Sorcerer::VERSION

PKG_FILES = FileList[
  'README.md',
  'Rakefile',
  'doc/*',
  'rakelib/*',
  'lib/**/*.rb',
  'test/**/*.rb',
]

BASE_RDOC_OPTIONS = [
  '--line-numbers', '--inline-source',
  '--title', 'Rake -- Ruby Make'
]

task :default => :test

RDOC_FILES = FileList['lib/**/*.rb', 'doc/**/*.rdoc'].exclude(/\bcontrib\b/)

if defined?(Rake::RDocTesk)
  rd = Rake::RDocTask.new("rdoc") do |rdoc|
    rdoc.rdoc_dir = 'html'
    rdoc.template = 'doc/jamis.rb'
    rdoc.title    = "Sorcerer -- Its Like Magic"
    rdoc.options = BASE_RDOC_OPTIONS.dup
    rdoc.options << '-SHN' << '-f' << 'darkfish' if defined?(DARKFISH_ENABLED) && DARKFISH_ENABLED
    rdoc.rdoc_files = RDOC_FILES
  end
end

if ! defined?(Gem)
  puts "Package Target requires RubyGEMs"
else
  SPEC = Gem::Specification.new do |s|
    s.name = 'sorcerer'
    s.version = PKG_VERSION
    s.summary = "Generate Source from Ripper ASTs"
    s.description = "Generate the original Ruby source from a Ripper-style abstract syntax tree."
    s.files = PKG_FILES
    s.require_path = 'lib'                         # Use these for libraries.
    s.has_rdoc = true
    s.extra_rdoc_files = RDOC_FILES.reject { |fn| fn =~ /\.rb$/ }.to_a
    s.rdoc_options = BASE_RDOC_OPTIONS
    s.author = "Jim Weirich"
    s.email = "jim.weirich@gmail.com"
    s.rubyforge_project = 'sorcerer'
    s.homepage = "http://github.com/jimweirich/sorcerer"
  end

  package_task = Gem::PackageTask.new(SPEC) do |pkg|
    pkg.need_zip = true
    pkg.need_tar = true
  end
end
