
namespace "git" do
  desc "Tag the current version of the project as #{PROJ}-#{PKG_VERSION}"
  task :tag do
    #sh "git tag #{PROJ}-#{PKG_VERSION}"
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
    #sh "gem push pkg/#{PROJ}-#{PKG_VERSION}.gem"
  end
end

task "new_version" => [:test, "git:ensure_clean", "git:tag", "gem:push"]
