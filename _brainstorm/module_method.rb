module Foo

  # Add the #event method to the extending class not instances of that class
  def self.included(base)
    base.extend(BarClassMeth)
    set_trace_func proc { |event, file, line, id, binding, classname|

      # Raise an error if there is no method following a command definition
      if event == "end"
        # look for end of class
        puts "end found: #{classname.inspect}"
        #set_trace_func(nil) if classname
      end
    }
  end

  module BarClassMeth
    
  end
  
end



class Baz

  module Bliz
  include Foo

  def self.new(*args, &block)
    puts "Baz bitches"
    instance = allocate
    instance.instance_variable_set("@potato", "potato")
    instance.send(:initialize, *args, &block)
    instance
  end
  
  def blah
    puts "blah"
  end
  puts "end"

end
end

b = Baz.new