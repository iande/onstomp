# -*- encoding: utf-8 -*-
require 'spec_helper'

module OnStomp::Interfaces
  describe EventManager do
    let(:eventable) {
      mock('eventable').tap do |m|
        m.extend EventManager
      end
    }
    describe ".bind_event / .trigger_event" do
      it "should bind a proc and call it when the event is triggered" do
        triggered = nil
        eventable.bind_event(:some_event_name,
          lambda { |a1, a2| triggered = [a1, a2] })
        eventable.trigger_event :some_event_name, 3, 'test'
        triggered.should == [3, 'test']
      end
    end

    describe "callbacks with exceptions" do
      it "does not allow exceptions to break the callback chain" do
        triggered = [false, false]
        eventable.bind_event(:an_event, lambda { |*_| raise "failed" })
        eventable.bind_event(:an_event, lambda { |x,y| triggered[0] = y; raise "failed again" })
        eventable.bind_event(:an_event, lambda { |x,y| triggered[1] = x })
        eventable.trigger_event :an_event, 4, 10
        triggered.should == [10, 4]
      end
    end
    
    describe ".event_callbacks" do
      it "should provide an empty array for an unbound event" do
        eventable.event_callbacks[:foo_bar_bazz].should == []
      end
    end
    
    describe "::create_event_method(s)" do
      before(:each) do
        class TestEventManager
          include EventManager
          create_event_method  :foo_event1
          create_event_methods :foo_event2
          create_event_methods :foo_event3, :before, :during, :after
        end
      end
      let(:test_eventable) {
        TestEventManager.new
      }
      
      it "should have a 'foo_event' method" do
        triggered = false
        test_eventable.foo_event1 { triggered = true }
        test_eventable.trigger_event :foo_event1, 'arg'
        triggered.should be_true
      end
      it "should have a 'on_foo_event2' method" do
        triggered = false
        test_eventable.on_foo_event2 { triggered = true }
        test_eventable.trigger_event :on_foo_event2, 'arg'
        triggered.should be_true
      end
      it "should have a 'before_foo_event3' method" do
        triggered = false
        test_eventable.before_foo_event3 { triggered = true }
        test_eventable.trigger_event :before_foo_event3, 'arg'
        triggered.should be_true
      end
      it "should have a 'during_foo_event3' method" do
        triggered = false
        test_eventable.during_foo_event3 { triggered = true }
        test_eventable.trigger_event :during_foo_event3, 'arg'
        triggered.should be_true
      end
      it "should have a 'after_foo_event3' method" do
        triggered = false
        test_eventable.after_foo_event3 { triggered = true }
        test_eventable.trigger_event :after_foo_event3, 'arg'
        triggered.should be_true
      end
    end
  end
end
