#!/usr/bin/env ruby

directory "html"

desc "Display the README file"
task :readme => "README.md" do
  sh "ghpreview README.md"
end

namespace "readme" do
  desc "Update the version in the readme"
  file "README.md" => ["lib/sorcerer/version.rb"] do
    open("README.md") do |ins|
      open("new_readme.txt", "w") do |outs|
        while line = ins.gets
          if line =~ /^\*\*Version: .*\*\*$/
            line = "**Version: #{PKG_VERSION}**"
          end
          outs.puts line
        end
      end
    end
    mv "README.md", "README.bak"
    mv "new_readme.txt", "README.md"
  end
end
