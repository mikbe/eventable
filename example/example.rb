$:.unshift File.expand_path(File.join(File.dirname(__FILE__), "/../lib"))
require 'eventable'

class EventedClass
  include Eventable
  event :stuff_happens
  event :other_stuff_happens

  def initialize
    # If you don't call super Eventable will raise an error
    super # <= VERY important, comment this out to see the error
    # do your initialize stuff
  end

  def make_stuff_happen(parent_id)
    # You handle concurrency however you want, threads or fibers, up to you.
    Thread.new{
      puts "firing :stuff_happens"
      fire_event(:stuff_happens, {:parent_id=>parent_id, :some_value => rand(1000)})
    }
  end

  def start_other_stuff_happening
    Thread.new {
      5.times do 
        sleep(rand(1)+2)
        puts "firing :other_stuff_happens"
        fire_event(:other_stuff_happens)
      end
    }
  end

end

class ListenerClass

  def initialize(some_object)
    @some_thing = some_object
    @some_thing.register_for_event(event: :stuff_happens, listener: self, callback: :stuff_happened)
  end

  def do_somestuff(parent_id, times=6)
    # I wrapped this in a thread to show it works cross threaded
    Thread.new{
      id = rand(1000)
      times.times do
        sleep(rand(2)+1)
        puts "[#{parent_id}, #{id}]: do_somestuff"
        @some_thing.make_stuff_happen(parent_id)
      end
    }
  end

  def stuff_happened(stuff)
    splat = stuff
    puts "[#{splat[:parent_id]}] stuff_happened callback: #{splat[:some_value]}"
  end

  def other_stuff_happened
    puts "[n/a] same_stuff_happened callback: n/a"
  end

end

# Now show it running
evented = EventedClass.new

# You can inject the evented class
listener = ListenerClass.new(evented)

# or attach to events outside of a listener class
evented.register_for_event(event: :other_stuff_happens, listener: listener, callback: :other_stuff_happened)

evented.start_other_stuff_happening
(1..3).each do |index|
  listener.do_somestuff(index)
  puts "[#{index}] did some stuff, sleeping"
  sleep(rand(3)+4)
  puts "[#{index}] slept"
end

puts "all done"
