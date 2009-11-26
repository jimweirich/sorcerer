
namespace "git" do
  task :tag do
    sh "git tag #{PROJ}-#{PKG_VERSION}"
  end
end
