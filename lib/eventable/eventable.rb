# Incredibly simple framework for adding events
module Eventable

  attr_reader :callbacks

  # Add the #event method to the extending class not instances of that class
  def self.included(base)
    base.extend(EventableClassMethods)
  end
  
  module EventableClassMethods
    
    # register an event
    def event(event_name)
      @events ||= []
      @events << event_name unless @events.include? event_name
    end
    
    # returns a list of registered events
    def events
      @events.clone
    end
    
  end

  def events
    self.class.events
  end
  
  # When the event happens the class where it happens runs this
  def fire_event(event, *return_value, &block)
    return false unless @callbacks[event] && !@callbacks[event].empty?
    @callbacks[event].each do |listener_id, callbacks|
      # this error trapping seems like unnecessary optimization, 
      # it shouldn't ever get here but if it does I need to know
      # begin
        listener = ObjectSpace._id2ref(listener_id)
        callbacks.each {|callback| listener.send callback, *return_value, &block}
      # rescue RangeError => re
      #   # bubble up the error if it's not a missing object error (missing object should never happen but...)
      #   raise re unless re.message.match(/is recycled object/)
      # end
    end
  end

  # Allows an object to listen for an event and have a callback run when it happens
  def register_for_event(args)
    [:event, :listener, :callback].each do |parameter|
      raise ArgumentError, "Missing parameter :#{parameter}" unless args[parameter]
    end

    event = args[:event]
    raise Errors::UnknownEvent unless events.include? event
    @callbacks ||= {}
    @callbacks[event] ||= {}
    
    listener    = args[:listener]
    listener_id = listener.object_id
    callback    = args[:callback]
    
    # save the callback info without creating a reference to the object
    @callbacks[event][listener_id] ||= []
    @callbacks[event][listener_id] << callback

    # remove the object from the callback list if it is destroyed
    ObjectSpace.define_finalizer(
      listener, 
      unregister_finalizer(event, listener_id, callback)
    )

  end

  # Allows objects to stop listening to events
  def unregister_for_event(args)
    event = args[:event]
    return unless @callbacks && @callbacks[event]
    
    listener_id = args[:listener_id] || args[:listener].object_id
    callback    = args[:callback]
    
    @callbacks[event].delete_if do |listener, callbacks|
      callbacks.delete(callback) if listener == listener_id
      callbacks.empty?
    end
  end

  # Wrapper for the finalize proc. You have to call a method
  # from define_finalizer; you can't just put this proc in it.
  def unregister_finalizer(event, listener_id, callback)
    proc {unregister_for_event(event: event, listener_id: listener_id, callback: callback)}
  end
  
end
