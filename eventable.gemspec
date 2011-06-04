# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "eventable/version"

Gem::Specification.new do |s|
  s.name        = "eventable"
  s.version     = Eventable::VERSION
  s.authors     = ["Mike Bethany"]
  s.email       = ["mikbe.tk@gmail.com"]
  s.homepage    = "http://mikbe.tk"
  s.summary     = %q{An incredibly simple event mixin module.}
  s.description = %q{Provides a simple, easy to use and understand event model. Other's did way too much for my needs, I just wanted a simple way to add, listen, and fire events in a class.}

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
