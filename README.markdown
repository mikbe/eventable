#Eventable#

An incredibly simple way to add events to your classes.

##Description##

Provides an easy to use and understand event model. Other systems did way too much for my needs: I didn't need to monitor network IO ports, I didn't want a central loop that polled IO, I just wanted a simple way to add real, non-polled events to a class and to register other classes to listen for those events.

If you want a simple way to add events to your classes without a bunch of other unrelated IO stuff this is the solution for you. (If you want to monitor IO events check out EventMachine)

You might be saying, "What about Observable? Why not just use that?" The problem with observable is that it saves a reference to the observing object. If you drop and add a bunch of observers without removing them from the observed object you've got the potential for a huge memory leak (depending on the size of your listeners of course).

With Eventable you don't have to worry about memory leaks because Eventable only make a reference to the listening object when it needs to talk to it. When it's done the reference goes out of scope and can be garbage collected. 

Eventable will even automatically remove registered listeners when they get garbage collected. You can set up a listener and not worry about removing your event hook yourself; it's done for you.

Eventable also allows for more fine-grain control than Observable. You can register for specific events instead of just saying, "Hey, let me know when anything changes."

##Concurrency considerations##

Events and threads do not scale well past a certain point but that's OK; they aren't meant to. They are meant for fast, simple communication beteen processes not large distributed processes like serving websites on massive server farms. If you need a solution that scales well to large distributed systems check out the Actor concurrency model.

##Install##

`$ gem install eventable`

##Usage Instructions##

* Include the module
* **Important:** If you have an initialize method `super` must be the first line of that method (see below). If you don't have an initialize method you don't have to add one. Super is called automatically for you.
* Add an event, e.g. `event :your_event`
* Fire the event when it should be fired: `fire_event(:your_event)`

To reiterate you **must** call `super` in your `initialize` method or Eventable won't work and you'll get an error. Eventable needs to create a mutex to make it thread safe, if you don't call `super` the mutex variable won't be created.

##Examples##
This example shows the basics of using Eventable to add an event to a class and listen for that event. (Without threading it's a bit pointless):

    require 'eventable'

    class EventClass
      include Eventable
  
      # This is all you have to do to add an event (after you include Eventable)
      event :stuff_happens

      # There's no initialize method so you do
      # not have to worry about calling super.

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

    => firing :stuff_happens
    => stuff happened callback: 575
    
This example shows you how you might actually use it in a multi-threaded environment but is a lot harder to read because of all the debug code:

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
        puts "[#{stuff[:parent_id]}] stuff_happened callback: #{stuff[:some_value]}"
      end
  
      def other_stuff_happened
        puts "[n/a] other_stuff_happened callback: n/a"
      end
  
    end

    # Now show it running
    evented = EventedClass.new

    # You can inject the evented class
    listener = ListenerClass.new(evented)

    # or attach to events outside of a listener class
    evented.register_for_event(event: :other_stuff_happens, listener: listener, callback: :other_stuff_happened)

    # Start firing off the events
    evented.start_other_stuff_happening
    
    (1..3).each do |index|
      listener.do_somestuff(index)
      puts "[#{index}] did some stuff, sleeping"
      sleep(rand(3)+4)
      puts "[#{index}] slept"
    end

    puts "all done"


##Version History##

**2014.09.10**
Ver: 0.2.1

* Verified to work with Ruby 2.1  
* Updated specs to RSpec 2.99  
* Updated dependencies and author links.

**2014.03.26**
Ver: 0.2.0

Updates:

Updating for Ruby 2.x

**2011.07.05**
Ver: 0.1.4

Updates:

* Added running specs to rake tasks (Colin Gemmell)

Bug fixes:

* Did not accept initialization parameters so caused errors if your class inherited from another class that needed them. (Paul Strong)

**2011.06.28**  
Ver: 0.1.3  

Updates:  

Callbacks are now threaded:  
This patches one of the last concurrency issues; if a callback takes a long time or hangs it won't affect any other callbacks or events that need to fire.  

It's your responsiblity to make sure your callback works, as long as it does the callback thread will go out of scope (unless you retain it) and everyone is happy.  

**2011.06.17**  
Ver: 0.1.2  

Design updates/fixes:

* Renamed most instance variables to help avoid name collisions.
* Threadsafe mutex creation. Make sure you call `super` in your class's initialize method! (Robert Klemme)

**2011.06.10**  
Ver: 0.1.1  

Features:  

* If events fired specifically returns true and returns false if it can't for whatever reason (e.g. no listeners registered).

Fixes:  

* Throws error if event is fired and no listeners are registered (Benjamin Yu)
* Workaround for RubyGems pre 1.8.3 date bug that locks up all of RubyGems (Benjamin Yu)


**2011.06.06**  
Ver: 0.1.0  
Went crazy and just completely wrapped all calls that modify or read callbacks cache with an instance mutex.

From what I understand locks are really expensive in Ruby so I'll need to clean this up and do some real performance testing.

Note:
Releasing just to stop RubyGems.org from showing last beta instead of newest beta when there are only --pre versions available of a gem. I get why they do it, but it's annoying to have people downloading beta 1 when you're really on beta 2. Plus I need to start using it myself...

**2011.06.05**  
Ver: 0.1.0.beta2  

* Wrapped #\_id2ref call in begin...rescue block. (Evan Phoenix)
* Added thread synchronization to calls that modify or read callbacks cache.

**2011.06.05**  
Ver: 0.1.0.beta1  
Completely redesigned from naive first attempt.  

**Added features**  

Now includes RSpecs.  

Garbage collection safe:  

* Won't keep references to listeners open.  
* Automatically removes garbage collected listeners from  event notifications.  


**2011.06.04**  
Ver: 0.0.1.alpha  
Just wrote it as a proof of concept. 


##Patches/Pull requests##

* Fork the project.
* Make your feature addition or bug fix (**do not** alter whitespace unless that is a bug!)
* Add RSpecs for the fix/feature. If you don't have specs I can't add it.
* Commit your changes. (**do not** change the rakefile, version, or history)
* Send a pull request. I respond to pull request very, very quickly.
