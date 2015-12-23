require File.expand_path('../lib/awesome_delete/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ['hw93']
  gem.email         = ['676018683@qq.com']
  gem.license       = 'MIT'
  gem.version       = AwesomeDelete::VERSION
  gem.summary       = 'Recursively delete appropriately'
  gem.description   = 'Recursively delete a collection and its all assoication with less sqls'

  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.name          = 'awesome_delete'
  gem.require_paths = ['lib']
  gem.homepage      = 'https://github.com/hw676018683/awesome_delete'

  gem.required_ruby_version = ">= 1.9.3"

  gem.add_runtime_dependency 'activerecord', '>= 4.0.0', '< 5'

  gem.add_development_dependency 'rspec-rails', '~> 3.0'
  gem.add_development_dependency 'combustion', '>= 0.5.2'
  gem.add_development_dependency 'database_cleaner'
end