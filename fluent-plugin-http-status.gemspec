# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |gem|
  gem.name          = "fluent-plugin-http-status"
  gem.version       = "0.0.4"
  gem.authors       = ["hiro-su"]
  gem.email         = ["h.sugipon@gmail.com"]
  gem.description   = %q{Fluentd input plugin for to get the http status}
  gem.summary       = %q{Fluentd input plugin for to get the http status}
  gem.homepage      = "https://github.com/hiro-su/fluent-plugin-http-status"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
  
  gem.add_development_dependency "fluentd"
  gem.add_development_dependency "polling"
  gem.add_development_dependency "rake", "~> 12.0"
  gem.add_development_dependency "test-unit", "~> 3.2"
  gem.add_runtime_dependency "fluentd"
  gem.add_runtime_dependency "polling"
end
