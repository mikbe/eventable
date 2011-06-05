require 'spec_helper'

describe Eventable do

  before(:each) do
      @evented = EventClass.new
      @listener = ListenClass.new
    end

  context "when specifiying an event" do

    it 'should list the event from the class' do
      EventClass.events.should include(:stuff_happens)
    end
    
    it 'should list more than one event' do
      EventClass.events.should include(:other_stuff_happens)
    end

    it 'should list the event from an instance of the class' do
      @evented.events.should include(:stuff_happens)
    end
    
    it 'should list more than one event from an instance' do
      @evented.events.should include(:other_stuff_happens)
    end

    it "should not add an event that's already been added" do
      eval %{
        class EventClass
          include Eventable
          event :stuff_happens
        end
      }
      EventClass.events.count.should == 2
    end

    it "should not add events to other classes" do
      eval %{
        class EventClass2
          include Eventable
          event :some_other_event
        end
      }
      EventClass.events.should_not include(:some_other_event)
    end
    
    it "should not allow its event list to be altered external" do
      events = EventClass.events
      events.pop
      events.should_not == EventClass.events
    end
  end
  
  context "when registering for an event" do

    context "and there is a missing parameter" do

      # these tests could be refactored into one...
      it "should raise an error if the event is not specified" do
        lambda{ 
          @evented.register_for_event(listener: @listener, callback: :callback)
        }.should raise_error(ArgumentError)
      end

      it "should raise an error if the listener is not specified" do
        lambda{ 
          @evented.register_for_event(event: :do_something, callback: :callback)
        }.should raise_error(ArgumentError)
      end

      it "should raise an error if the callback is not specified" do
        lambda{ 
          @evented.register_for_event(event: :do_something, listener: @listener)
        }.should raise_error(ArgumentError)
      end

    end
    
    # For now not going to raise an error if the listener callback method
    # doesn't exist since it might be created later dynamically

    it "should raise an error if the event doesn't exist" do
      foo = Class.new
      lambda{ 
        @evented.register_for_event(event: :nonexistent, listener: foo, callback: :bar)
      }.should raise_error(Eventable::Errors::UnknownEvent)
    end

    it "should not raise an error when registering for events that do exist" do
      lambda{ 
        @evented.register_for_event(event: :stuff_happens, listener: @listener, callback: :callback)
      }.should_not raise_error
    end

    # I hate looking at the internal state but how else can I check these without testing more than just this?

    it "should allow multiple callbacks to the same method from different events" do
      @evented.register_for_event(event: :stuff_happens, listener: @listener, callback: :callback)
      @evented.register_for_event(event: :other_stuff_happens, listener: @listener, callback: :callback)
      @evented.callbacks.count.should == 2 
    end
    
    it "should not add a callback that's already been added" do
      @evented.register_for_event(event: :stuff_happens, listener: @listener, callback: :callback)
      @evented.register_for_event(event: :stuff_happens, listener: @listener, callback: :callback)
      @evented.callbacks[:stuff_happens].count.should == 1 
    end

    it "should allow multiple instances of the same class to register the same callback for the same event" do
      listener2 = ListenClass.new
      @evented.register_for_event(event: :stuff_happens, listener: @listener, callback: :callback)
      @evented.register_for_event(event: :stuff_happens, listener: listener2, callback: :callback)
      @evented.callbacks[:stuff_happens].keys.should == [@listener.object_id, listener2.object_id]
    end

    it "should allow callbacks from the same event to different methods in the same instance" do
      @evented.register_for_event(event: :stuff_happens, listener: @listener, callback: :callback)
      @evented.register_for_event(event: :stuff_happens, listener: @listener, callback: :callback2)
      @evented.do_event
      @listener.callback?.should be_true
      @listener.callback2?.should be_true
    end

    it "should allow callbacks to class methods" do
      # should be a no brainer because a class is an object too, but just to be sure
      @evented.register_for_event(event: :stuff_happens, listener: ListenClass, callback: :class_callback)
      @evented.do_event
      ListenClass.class_callback?.should be_true
    end

  end
  
  context "when unregistering for an event" do
  
    it "should remove a callback" do
      @evented.register_for_event(event: :stuff_happens, listener: @listener, callback: :callback)
      @evented.callbacks[:stuff_happens].keys.should include(@listener.object_id) # <= just to be sure...
      @evented.unregister_for_event(event: :stuff_happens, listener: @listener, callback: :callback)
      @evented.callbacks[:stuff_happens].keys.should_not include(@listener.object_id)
    end
  
    it "should not call a callback that has been removed" do
      @evented.register_for_event(event: :stuff_happens, listener: @listener, callback: :callback)
      @evented.unregister_for_event(event: :stuff_happens, listener: @listener, callback: :callback)
      @evented.do_event
      @listener.callback?.should_not be_true
    end
  
    it "should automatically remove callbacks to objects that are garbage collected" do
      listener_object_id = nil
      (0..1).each do
        listener = ListenClass.new
        listener_object_id ||= listener.object_id
        @evented.register_for_event(event: :stuff_happens, listener: listener, callback: :callback)
      end
      GC.start
      @evented.callbacks[:stuff_happens].keys.should_not include(listener_object_id) 
    end
  
  end

  context "when an event is fired" do
  
    it "should call back the specified method when the event is fired" do
      @evented.register_for_event(event: :stuff_happens, listener: @listener, callback: :callback)
      @evented.do_event
      @listener.callback?.should be_true
    end
      
    it "should not call back the wrong method when the event is fired" do
      @evented.register_for_event(event: :stuff_happens, listener: @listener, callback: :callback)
      @evented.do_event
      @listener.callback2?.should_not be_true
    end
    
    it "should call back more than one class" do
      listener2 = ListenClass.new
    
      @evented.register_for_event(event: :stuff_happens, listener: @listener, callback: :callback)
      @evented.register_for_event(event: :stuff_happens, listener: listener2, callback: :callback2)
    
      @evented.do_event
    
      @listener.callback?.should be_true
      listener2.callback2?.should be_true
    end

    it "should not call back the wrong method when using multiple classes" do
      listener2 = ListenClass.new
    
      @evented.register_for_event(event: :stuff_happens, listener: @listener, callback: :callback)
      @evented.register_for_event(event: :stuff_happens, listener: listener2, callback: :callback2)
    
      @evented.do_event
    
      @listener.callback2?.should_not be_true
      listener2.callback?.should_not be_true
    end

  end

end

# Test classes
class EventClass
  include Eventable
  event :stuff_happens
  event :other_stuff_happens
  def do_event
    fire_event(:stuff_happens)
  end
end

class ListenClass
  def self.class_callback?
    @@callback
  end
  def self.class_callback
    @@callback = true
  end
  def callback?
    @callback
  end
  def callback
    @callback = true
  end
  def callback2?
    @callback2
  end
  def callback2
    @callback2 = true
  end
end


