module Eventable
  module Errors
    UnknownEvent = Class.new(StandardError)
    SuperNotCalledInInitialize = Class.new(ScriptError)
  end
end