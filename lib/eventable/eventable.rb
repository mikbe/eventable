# Incredibly simple framework for adding events
module Eventable

  # Add the #event method for the class not the instance
  def self.included(base)
    base.extend(EventableClassMethods)
  end
  
  module EventableClassMethods
    
    # Just for tracking what events were added
    # It might be useful to add some kind of 
    # method signiture just to demonstrate how 
    # a callback should look but I just use hashes
    def event(event_name)
      @@events ||= []
      @@events << event_name
    end
    
    # In case you want to test what events a class has
    def events
      @@events
    end
    
  end

  # Does it make sense to bubble down the event list?
  def events
    @@events
  end

  # When the event happens the class where it happens runs this
  def fire_event(event_name, *return_values, &return_block)
    return unless @events[event_name] && !@events[event_name].empty?
    @events[event_name].each do |callback|
       callback.call(return_values, return_block)
    end
  end

  # Allows an object to listen for an event and have a callback run when it happens
  def register_for_event(event_name, &callback)
    @events ||= {}
    @events[event_name] ||= []
    @events[event_name] << callback
  end

  # Allows objects to stop listening too
  def unregister_for_event(event_name, &callback)
    return unless @events || @events[event_name]
    @events[event_name].delete(callback)
  end
  
end
