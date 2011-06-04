$:.unshift File.expand_path(File.join(File.dirname(__FILE__), "/../lib"))
require 'eventable'

class ThingOne
  include Eventable
  event :stuff_happens
  
  def doing(parent_id)
    # You handle concurrency however you want, threads or fibers, up to you.
    Thread.new{
      fire_event(:stuff_happens, {:parent_id=>parent_id, :some_value => rand(1000)})
    }
  end
  
end

class ThingTwo
  
  # Dependency injection works fine
  def initialize(some_object)
    @some_thing = some_object
    
    # With return data
    @some_thing.register_for_event(:stuff_happens) {|return_data| stuff_happened(*return_data)}
    
    # Without return data - notice it's the same event
    @some_thing.register_for_event(:stuff_happens) {same_stuff_happened}
  
  end

  def do_somestuff(parent_id, times=6)
    # I just wrapped this in a thread to show it works cross threaded
    Thread.new{
      id = rand(1000)
      times.times do
        sleep(rand(2)+1)
        puts "[#{parent_id}, #{id}]: do_somestuff"
        @some_thing.doing(parent_id)
      end
    }
  end
  
  def stuff_happened(stuff)
    splat = stuff
    puts "[#{splat[:parent_id]}] stuff_happened callback: #{splat[:some_value]}"
  end
  
  def same_stuff_happened
    puts "[n/a] same_stuff_happened callback: n/a"
  end
  
end

# Now show it running
t1 = ThingOne.new
t2 = ThingTwo.new(t1)

(1..3).each do |index|
  t2.do_somestuff(index)
  puts "[#{index}] did some stuff, sleeping"
  sleep(rand(3)+4)
  puts "[#{index}] slept"
end


