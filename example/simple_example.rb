$:.unshift File.expand_path(File.join(File.dirname(__FILE__), "/../lib"))
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


