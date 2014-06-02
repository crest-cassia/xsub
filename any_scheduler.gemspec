# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'any_scheduler/version'

Gem::Specification.new do |spec|
  spec.name          = "any_scheduler"
  spec.version       = AnyScheduler::VERSION
  spec.authors       = ["Yohsuke Murase"]
  spec.email         = ["yohsuke.murase@gmail.com"]
  spec.description   = %q{A wrapper for job schedulers. You can submit jobs to various schedulers in a unified way.}
  spec.summary       = %q{A wrapper for job schedulers.}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
end
