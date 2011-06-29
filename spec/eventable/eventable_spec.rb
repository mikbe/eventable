require 'spec_helper'

# Callbacks are threaded to avoid blocking so tests need to wait for the callback to be scheduled and run
CALLBACK_WAIT = 0.01

describe Eventable do

  before(:each) do
    @evented = EventClass.new
    @listener = ListenClass.new
  end

  context "when inheriting eventable" do

    it "should not raise an error if class has no initialize method" do
      lambda{
        class Foo
          include Eventable
          event :do_stuff
        end
      f = Foo.new
      f.fire_event(:do_stuff)
      }.should_not raise_error
    end

    it "should not raise an error if super is called in initialize" do
      lambda{
        class Foo
          include Eventable
          event :do_stuff
          def initialize
            super
          end
        end
        f = Foo.new
        f.fire_event(:do_stuff)
      }.should_not raise_error
    end

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
      sleep(CALLBACK_WAIT)
      @listener.callback?.should be_true
      @listener.callback2?.should be_true
    end

    it "should allow callbacks to class methods" do
      # should be a no brainer because a class is an object too, but just to be sure
      @evented.register_for_event(event: :stuff_happens, listener: ListenClass, callback: :class_callback)
      @evented.do_event
      sleep(CALLBACK_WAIT)
      ListenClass.class_callback?.should be_true
    end

    context "when multiple classes mixin eventable" do

      # this is kind of redundant but just to be sure there's no bleed over through the mixin module

      it "should not call the wrong class" do
        another_evented = AnotherEventClass.new
        another_listener = AnotherListenClass.new
        @evented.register_for_event(event: :stuff_happens, listener: @listener, callback: :callback)
        another_evented.register_for_event(event: :stuff_happens, listener: another_listener, callback: :callback)
        @evented.do_event
        sleep(CALLBACK_WAIT)
        @listener.callback?.should be_true
        another_listener.callback?.should_not be_true
      end

      it "should not call the wrong class when both evented classes fire events" do
        another_evented = AnotherEventClass.new
        another_listener = AnotherListenClass.new
        @evented.register_for_event(event: :stuff_happens, listener: @listener, callback: :callback)
        another_evented.register_for_event(event: :stuff_happens, listener: another_listener, callback: :callback2)
        @evented.do_event
        another_evented.do_event
        sleep(CALLBACK_WAIT)
        @listener.callback?.should be_true
        another_listener.callback2?.should be_true
      end

    end

  end

  context "when unregistering for an event" do

    it "should not throw an error if unregistering for an event you weren't registered for" do
      # Is this supporting sloppy programming(bad) or lazy programming(good)?
      lambda{@evented.unregister_for_event(event: :stuff_happens, listener: @listener, callback: :callback)}.should_not raise_error
    end

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

    it "should return false if the event did not fire" do
      @evented.do_event
      @evented.do_event.should be_false
    end

    it "should return true if the event did fire" do
      @evented.register_for_event(event: :stuff_happens, listener: @listener, callback: :callback)
      @evented.do_event.should be_true
    end

    it "should not throw an error if no listeners have been registered for an event" do
      @evented.do_event
      lambda{@evented.do_event}.should_not raise_error
    end

    it "should call back the specified method when the event is fired" do
      @evented.register_for_event(event: :stuff_happens, listener: @listener, callback: :callback)
      @evented.do_event
      sleep(CALLBACK_WAIT)
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
      sleep(CALLBACK_WAIT)
      @listener.callback?.should be_true
      listener2.callback2?.should be_true
    end

    it "should not call back the wrong method when using multiple classes" do
      listener2 = ListenClass.new

      @evented.register_for_event(event: :stuff_happens, listener: @listener, callback: :callback)
      @evented.register_for_event(event: :stuff_happens, listener: listener2, callback: :callback2)

      @evented.do_event
      sleep(CALLBACK_WAIT)
      @listener.callback2?.should_not be_true
      listener2.callback?.should_not be_true
    end

    context "and it has return data" do

      it "should return the return values" do
        @evented.register_for_event(event: :stuff_happens, listener: @listener, callback: :callback_with_args)
        a, b, c = rand(100), rand(100), rand(100)
        @evented.do_event_with_args(a,b,c)
        sleep(CALLBACK_WAIT)
        @listener.callback_with_args?.should == [a,b,c]
      end

      it "should return a block" do
        @evented.register_for_event(event: :stuff_happens, listener: @listener, callback: :callback_with_block)
        block = proc {"a block"}
        @evented.do_event_with_block(&block)
        sleep(CALLBACK_WAIT)
        @listener.callback_with_block?.should == block
      end

      it "should return the return values and a block" do
        @evented.register_for_event(event: :stuff_happens, listener: @listener, callback: :callback_with_args_and_block)
        a, b, c, block = rand(100), rand(100), rand(100), proc {"a block"}
        @evented.do_event_with_args_and_block(a,b,c,&block)
        sleep(CALLBACK_WAIT)
        @listener.callback_with_args_and_block?.should == [a,b,c,block]
      end

    end

    context "when multithreading" do

      it "should not block on callbacks" do
        bc = BlockingClass.new
        @evented.register_for_event(event: :stuff_happens, listener: bc, callback: :blocking_call)
        start_time = Time.now
        @evented.do_event
        sleep(CALLBACK_WAIT * 2) # Just to make sure the event cycle starts
        Time.now.should_not > start_time + 1
      end

    end

  end

end

# Test classes

class BlockingClass
  def blocking_call
    # I don't know how long this will take but it's a lot longer than 1 second
    1000000000.times { Math.sqrt(98979872938749283749729384792734927) }
    non_blocking_call
  end
  def non_blocking_call
    "all done"
  end
end

class EventClass
  include Eventable
  event :stuff_happens
  event :other_stuff_happens
  def do_event(event=:stuff_happens)
    fire_event(event)
  end
  def do_event_with_args(*args)
    fire_event(:stuff_happens, *args)
  end
  def do_event_with_block(&block)
    fire_event(:stuff_happens, &block)
  end
  def do_event_with_args_and_block(*args, &block)
    fire_event(:stuff_happens, *args, &block)
  end
end

class AnotherEventClass
  include Eventable
  event :stuff_happens
  event :different_happens

  def do_event(event=:stuff_happens)
    fire_event(event)
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
  def callback_with_args(a,b,c)
    @a, @b, @c = a, b, c
  end
  def callback_with_args?
    [@a, @b, @c]
  end
  def callback_with_block(&block)
    @block = block
  end
  def callback_with_block?
    @block
  end
  def callback_with_args_and_block(a,b,c,&block)
    @a, @b, @c, @block = a, b, c, block
  end
  def callback_with_args_and_block?
    [@a, @b, @c, @block]
  end
end

class AnotherListenClass
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


