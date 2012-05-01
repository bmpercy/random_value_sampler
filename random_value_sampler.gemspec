# -*- encoding: utf-8 -*-
require File.join(File.dirname(File.expand_path(__FILE__)), 'lib/random_value_sampler/version')

Gem::Specification.new do |gem|
  gem.authors       = ["Brian Percival"]
  gem.email         = ["bpercival@goodreads.com"]
  gem.description   = %q{Class for sampling from arbitrary probability distributions}
  gem.summary       = %q{Class for sampling from arbitrary probability distributions, particular discrete random variables with lookup-table-like PMFs}
  gem.homepage      = "https://github.com/bmpercy/random_value_sampler"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "random_value_sampler"
  gem.require_paths = ["lib"]
  gem.version       = RandomValueSampler::VERSION
  gem.add_development_dependency 'rake'
end
