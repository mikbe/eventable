require 'thread'

# Incredibly simple framework for adding events
module Eventable

  module EventableEventMethods

    # register an event
    def event(event_name)
      @eventable_events ||= []
      @eventable_events << event_name unless @eventable_events.include? event_name
    end

    # returns a list of registered events
    def events
      @eventable_events.clone
    end

  end

  def events
    self.class.events
  end

  # Allows for dynamic discovery of hooked callbacks
  attr_reader :callbacks

  # Add the #event method to the extending class not instances of that class
  def self.included(base)
    base.extend(EventableEventMethods)
  end

  def initialize(*args)
    super
    @eventable_mutex = Mutex.new
  end

  # When the event happens the class where it happens runs this
  def fire_event(event, *return_value, &block)
    check_mutex
    @eventable_mutex.synchronize {

      return false unless @callbacks && @callbacks[event] && !@callbacks[event].empty?

      @callbacks[event].each do |listener_id, callbacks|
        begin
          listener = ObjectSpace._id2ref(listener_id)
          callbacks.each do |callback|
            listener.send callback, *return_value, &block
          end
        rescue RangeError => re
          # Don't bubble up a missing recycled object, I don't care if it's not there, I just won't call it
          raise re unless re.message.match(/is recycled object/)
        end
      end
    }
    true
  end

  # Allows an object to listen for an event and have a callback run when the event happens
  def register_for_event(args)
    [:event, :listener, :callback].each do |parameter|
      raise ArgumentError, "Missing parameter :#{parameter}" unless args[parameter]
    end

    # Make access to the callback array threadsafe
    check_mutex
    @eventable_mutex.synchronize {
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

      # will remove the object from the callback list if it is destroyed
      ObjectSpace.define_finalizer(
        listener, 
        unregister_finalizer(event, listener_id, callback)
      )
    }
  end

  # Allows objects to stop listening to events
  def unregister_for_event(args)
    check_mutex
    @eventable_mutex.synchronize {
      event = args[:event]
      return unless @callbacks && @callbacks[event]

      listener_id = args[:listener_id] || args[:listener].object_id
      callback    = args[:callback]
      @callbacks[event].delete_if do |listener, callbacks|
        callbacks.delete(callback) if listener == listener_id
        callbacks.empty?
      end
    }
  end

  private

  def check_mutex
    raise Errors::SuperNotCalledInInitialize, "You must include super in your class's initialize method" unless @eventable_mutex
  end

  # Wrapper for the finalize proc. You have to call a method
  # from define_finalizer; you can't just put this proc in there.
  def unregister_finalizer(event, listener_id, callback)
    proc {unregister_for_event(event: event, listener_id: listener_id, callback: callback)}
  end

end
