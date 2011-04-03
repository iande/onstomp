# -*- encoding: utf-8 -*-
require 'spec_helper'

module OnStomp::Interfaces
  describe ConnectionEvents do
    let(:client) { mock('client') }
    let(:eventable) {
      mock('eventable', :client => client).tap do |m|
        m.extend ConnectionEvents
      end
    }
  
    describe "connection event methods" do
      it "should provide a 'on_established' event" do
        triggered = false
        eventable.on_established { triggered = true }
        eventable.trigger_connection_event :established
        triggered.should be_true
      end
      it "should provide a 'on_closed' event" do
        triggered = false
        eventable.on_closed { triggered = true }
        eventable.trigger_connection_event :closed
        triggered.should be_true
      end
      it "should provide a 'on_died' event" do
        triggered = false
        eventable.on_died { triggered = true }
        eventable.trigger_connection_event :died
        triggered.should be_true
      end
      it "should provide a 'on_terminated' event" do
        triggered = false
        eventable.on_terminated { triggered = true }
        eventable.trigger_connection_event :terminated
        triggered.should be_true
      end
    end
    
    describe ".install_bindings_from_client" do
      let(:callback1) { mock('callback1') }
      let(:callback2) { mock('callback2') }
      let(:callback3) { mock('callback3') }
      
      it "should bind events from the hash and trigger connected" do
        eventable.stub(:version => 'x.y')
        eventable.should_receive(:bind_event).with(:ev1, callback3)
        eventable.should_receive(:bind_event).with(:ev1, callback2)
        eventable.should_receive(:bind_event).with(:ev2, callback1)
        eventable.should_receive(:trigger_connection_event).
          with(:established, "STOMP x.y connection negotiated")
        eventable.install_bindings_from_client :ev1 => [callback3, callback2], 
          :ev2 => [callback1]
      end
    end
  end
end
