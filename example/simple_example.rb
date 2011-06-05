$:.unshift File.expand_path(File.join(File.dirname(__FILE__), "/../lib"))
require 'eventable'

class ThingOne
  include Eventable
  event :stuff_happens
  
  def do_event
    fire_event(:stuff_happens, {:some_value => rand(1000)})
  end
end

class ThingTwo
  
  # Dependency injection works fine
  def initialize(some_object)
    @some_thing = some_object
    @some_thing.register_for_event(:stuff_happens) {|return_data| stuff_happened(*return_data)}
  end

  def do_somestuff
    @some_thing.do_event
  end
  
  def stuff_happened(stuff)
    puts "stuff happened callback"
  end

end

# Now show it running
t2 = ThingTwo.new(ThingOne.new)
t2.do_somestuff()
sleep(1)


