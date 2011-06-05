#Eventable#

An incredibly simple way to add events to your classes.


##Description##

Eventable provides a simple, easy to use and understand event model. Other's did way too much for my needs, I just wanted a simple way to add, listen, and fire events in a class.

Eventable couldn't be easier to use. 

This example just shows you the basics of using the module. (Without threading it's a bit pointless):

    require 'eventable'

    class EventClass
      include Eventable
      event :stuff_happens
  
      # don't name your method fire_event, that's taken
      def do_event
        puts "firing :stuff_happens"
        fire_event(:stuff_happens, rand(1000))
      end
      
    end

    class ListenClass
 
      def stuff_happened(stuff)
        puts "stuff happened callback: #{stuff}"
      end

    end

    # Now show it running
    evented   = EventClass.new
    listener  = ListenClass.new
    evented.register_for_event(event: :stuff_happens, listener: listener, callback: :stuff_happened)
    evented.do_event
    sleep(1)


    
This example shows you how you might actually use it in a multi-threaded environment but is a lot harder to read because of all the debug code:

    require 'eventable'

    class EventedClass
      include Eventable
      event :stuff_happens
      event :other_stuff_happens
  
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


##Version History##

**2011.06.06**  
Ver: 0.1.0.beta1
Completely redesigned from naive first attempt.

**Added features**  

Now includes RSpecs.

Garbage collection safe:  
* Won't keep references to listeners open. 
* Automatically removes garbage collected listeners from event notifications.  


**2011.06.04**  
Ver: 0.0.1.alpha  
Just wrote it as a proof of concept.  
