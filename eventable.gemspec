# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
# Kludge for older RubyGems not handling unparsable dates gracefully 
# (psych 1.2.0 gem wouldn't build on test system so we're stuck with syck)
YAML::ENGINE.yamler = 'syck' 
require "rubygems"
require "eventable/version"

Gem::Specification.new do |s|
  s.name        = "eventable"
  s.version     = Eventable::VERSION
  s.authors     = ["Mike Bethany"]
  s.email       = ["mikbe.tk@gmail.com"]
  s.homepage    = "http://mikbe.tk/projects#eventable"
  s.summary     = %q{An incredibly simple and easy to use event mixin module.}
  s.description = %q{Provides an easy to use and understand event model. If you want a simple, light-weight way to add events to your classes this is the solution for you.}

  s.add_development_dependency('rspec', "~>2.6")

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {spec}/*`.split("\n")
  s.require_paths = ["lib"]
end
