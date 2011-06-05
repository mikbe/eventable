$:.unshift File.expand_path(File.join(File.dirname(__FILE__), "/../lib"))
require 'eventable'

class EventClass
  include Eventable
  
  # This is all you have to do to add an event (after you include Eventable)
  event :stuff_happens

  # don't name your method fire_event, that's taken
  def do_event
    puts "firing :stuff_happens"
    # And this is all you have to do to make the event happen
    fire_event(:stuff_happens, rand(1000))
  end
  
end

class ListenClass

  def stuff_happened(stuff)
    puts "stuff happened callback: #{stuff}"
  end

end

# Create an instance of a class that has an event
evented   = EventClass.new

# Create a class that listens for that event
listener  = ListenClass.new

# Register the listener with the instance that will have the event
evented.register_for_event(event: :stuff_happens, listener: listener, callback: :stuff_happened)

# We'll just arbitrarilly fire the event to see how it works
evented.do_event

# Wait just to be sure you see it happen
sleep(1)


