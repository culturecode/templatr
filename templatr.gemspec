$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "templatr/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "templatr"
  s.version     = Templatr::VERSION
  s.authors     = ["Ryan Wallace", "Nicholas Jakobsen"]
  s.email       = ["contact@culturecode.ca"]
  s.homepage    = "https://github.com/culturecode/templatr"
  s.summary     = "Add custom fields to your models. "
  s.description = "Add custom fields to your models. "

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", "~> 3.2"

  s.add_development_dependency "pg"
end
