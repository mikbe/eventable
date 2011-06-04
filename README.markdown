#Eventable#

An incredibly simple way to add events to your classes.


##Description##

Eventable provides a simple, easy to use and understand event model. Other's did way too much for my needs, I just wanted a simple way to add, listen, and fire events in a class.

Eventable couldn't be easier to use. 

This example just shows you the bare basics of using the module. (Without threading it's a bit pointless):

    require 'eventable'

    class ThingOne
      include Eventable
      event :stuff_happens
  
      def doing
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
        @some_thing.doing
      end
  
      def stuff_happened(stuff)
        puts "stuff happened callback"
      end

    end

    # Now show it running
    t2 = ThingTwo.new(ThingOne.new)
    t2.do_somestuff()
    sleep(1)
    
    
This example shows you how you might actually use it in a multi-threaded environment but is a lot harder to read because of all the debug code:

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
    t2 = ThingTwo.new(ThingOne.new)
    (1..3).each do |index|
      t2.do_somestuff(index)
      puts "[#{index}] did some stuff, sleeping"
      sleep(rand(3)+4)
      puts "[#{index}] slept"
    end


##To do:##

* Develop tests. This was all done on a quick spike with the example acting as a form of testing.
* See if I can do some of the menial housekeeping for the user.
* See if I can add method prototypes to the event declaration (might be a bad idea in Rub) or make it work better with a variety of return values.

##Version History##

**2011.06.04**  
Ver: 0.0.1.alpha  
Just wrote it as a proof of concept.  
