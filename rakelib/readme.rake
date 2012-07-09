#!/usr/bin/env ruby

begin
  require 'redcloth'
  directory "html"

  desc "Display the README file"
  task :readme => "html/README.html" do
    sh "open html/README.html"
  end

  desc "format the README file"
  task "html/README.html" => ['html', 'README.textile'] do
    open("README.textile") do |source|
      open('html/README.html', 'w') do |out|
        out.write(RedCloth.new(source.read).to_html)
      end
    end
  end
rescue LoadError => ex
  task :readme do
    fail "Install RedCloth to generate the README"
  end
end

