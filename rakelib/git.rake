namespace "git" do
  desc "Tag the current version of the project as #{PROJ}-#{PKG_VERSION}"
  task :tag do
    sh "git tag #{PROJ}-#{PKG_VERSION}"
  end

  desc "Fail if the current project is not clean"
  task :ensure_clean do
    out = `git status | grep "nothing to commit"`
    if out == ''
      fail "Repo is not clean"
    end
  end
end

namespace "gem" do
  desc "Build and Push the current gem"
  task :push => :gem do
    fail "Can't push beta versions (#{PKG_VERSION})" if
      Sorcerer::VERSION_NUMBERS.size > 3
    sh "gem push pkg/#{PROJ}-#{PKG_VERSION}.gem"
  end
end

task "version" do
  puts PKG_VERSION
end

module Version
  def self.write(build, beta)
    open("lib/sorcerer/version.rb", "w") do |out|
      out.puts "module Sorcerer"
      out.puts "  VERSION_MAJOR = #{Sorcerer::VERSION_MAJOR}"
      out.puts "  VERSION_MINOR = #{Sorcerer::VERSION_MINOR}"
      out.puts "  VERSION_BUILD = #{build}"
      out.puts "  VERSION_BETA  = #{beta}"
      out.puts
      out.puts "  VERSION_NUMBERS = [VERSION_MAJOR, VERSION_MINOR, VERSION_BUILD] +"
      out.puts "    (VERSION_BETA > 0 ? [VERSION_BETA] : [])"
      out.puts
      out.puts "  VERSION = VERSION_NUMBERS.join('.')"
      out.puts "end"
    end
  end
end

namespace "version" do
  desc "Cut a new version"
  task "cut" => [:test, "git:ensure_clean", "git:tag", "gem:push"]

  namespace "bump" do
    desc "Bump the Beta version"
    task "beta" do
      Version.write(Sorcerer::VERSION_BUILD, Sorcerer::VERSION_BETA+1)
    end

    desc "Bump the Build version"
    task "build" do
      Version.write(Sorcerer::VERSION_BUILD+1, 0)
    end
  end
end

