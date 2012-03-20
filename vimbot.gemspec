# -*- encoding: utf-8 -*-
require File.expand_path("../lib/vimbot/version", __FILE__)

Gem::Specification.new do |s|
  s.name        = "vimbot"
  s.version     = Vimbot::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Max Brunsfeld"]
  s.email       = ["maxbrunsfeld@gmail.com"]
  s.homepage    = "https://github.com/maxbrunsfeld/vimbot"
  s.summary     = "Fluid vim automation with Ruby"
  s.description = "Automate Vim with Ruby to allow for TDD/BDD of Vim plugins and scripts"

  s.add_development_dependency "bundler", ">= 1.0.0"
  s.add_development_dependency "rake"
  s.add_development_dependency "rspec", "~> 2.7.0"

  s.files        = `git ls-files`.split("\n")
  s.require_path = 'lib'
end
