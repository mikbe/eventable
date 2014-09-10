# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)

require "rubygems"
require "eventable/version"

Gem::Specification.new do |s|
  s.name        = "eventable"
  s.version     = Eventable::VERSION
  s.authors     = ["Mike Bethany"]
  s.email       = ["mike@mikebethany.com"]
  s.homepage    = "http://mikebethany.com"
  s.summary     = %q{An incredibly simple and easy to use event mixin module.}
  s.description = %q{Provides an easy to use and understand event model. If you want a simple, light-weight way to add events to your classes this is the solution for you.}
  s.license     = 'MIT'

  s.required_ruby_version = ">= 1.9.2"

  s.add_development_dependency('rspec', "~>2.99")
  s.add_development_dependency('bundler', "~>1.6")

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {spec}/*`.split("\n")
  s.require_paths = ["lib"]
end
