$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "templatr/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "templatr"
  s.version     = Templatr::VERSION
  s.authors     = ["TODO: Your name"]
  s.email       = ["TODO: Your email"]
  s.homepage    = "TODO"
  s.summary     = "TODO: Summary of Templatr."
  s.description = "TODO: Description of Templatr."

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", "~> 3.2"

  s.add_development_dependency "pg"
end
