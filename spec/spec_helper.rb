$: << '.'
$:.unshift File.expand_path(File.join(File.dirname(__FILE__), "/../lib"))
require 'rspec'
require 'eventable'
