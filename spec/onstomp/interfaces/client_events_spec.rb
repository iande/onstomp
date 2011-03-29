# -*- encoding: utf-8 -*-
require 'spec_helper'

module OnStomp::Interfaces
  describe ClientEvents do
    let(:connection) { mock('connection') }
    let(:eventable) {
      mock('eventable').tap do |m|
        m.extend ClientEvents
      end
    }
    
    describe "client frame events" do
      [ :ack, :nack, :begin, :abort, :commit, :send, :subscribe,
        :unsubscribe, :disconnect, :client_beat ].each do |ftype|
        it "should provide an 'on_#{ftype}' event" do
          frame = if ftype == :client_beat
            OnStomp::Components::Frame.new
          else
            OnStomp::Components::Frame.new(ftype.to_s.upcase)
          end
          triggered = false
          eventable.__send__(:"on_#{ftype}") { triggered = true }
          eventable.trigger_after_transmitting frame
          triggered.should be_true
        end
        it "should provide a 'before_#{ftype}' event" do
          frame = if ftype == :client_beat
            OnStomp::Components::Frame.new
          else
            OnStomp::Components::Frame.new(ftype.to_s.upcase)
          end
          triggered = false
          eventable.__send__(:"before_#{ftype}") { triggered = true }
          eventable.trigger_before_transmitting frame
          triggered.should be_true
        end
      end
    end
    
    describe "broker frame events" do
      [ :error, :message, :receipt, :broker_beat ].each do |ftype|
        it "should provide an 'on_#{ftype}' event" do
          frame = if ftype == :broker_beat
            OnStomp::Components::Frame.new
          else
            OnStomp::Components::Frame.new(ftype.to_s.upcase)
          end
          triggered = false
          eventable.__send__(:"on_#{ftype}") { triggered = true }
          eventable.trigger_after_receiving frame
          triggered.should be_true
        end
        it "should provide a 'before_#{ftype}' event" do
          frame = if ftype == :broker_beat
            OnStomp::Components::Frame.new
          else
            OnStomp::Components::Frame.new(ftype.to_s.upcase)
          end
          triggered = false
          eventable.__send__(:"before_#{ftype}") { triggered = true }
          eventable.trigger_before_receiving frame
          triggered.should be_true
        end
      end
    end
    
    describe "frame io events" do
      let(:frame) {
        OnStomp::Components::Frame.new
      }
      [:transmitting, :receiving].each do |evtype|
        it "should provide a 'before_#{evtype}' event" do
          triggered = false
          eventable.__send__(:"before_#{evtype}") { triggered = true }
          eventable.__send__(:"trigger_before_#{evtype}", frame)
          triggered.should be_true
        end
        
        it "should provide an 'after_#{evtype}' event" do
          triggered = false
          eventable.__send__(:"after_#{evtype}") { triggered = true }
          eventable.__send__(:"trigger_after_#{evtype}", frame)
          triggered.should be_true
        end
      end
    end
    
    describe "connection events" do
      [:established, :terminated, :died, :closed].each do |ctype|
        it "should store in pending connection events if there is no connection" do
          triggered = nil
          eventable.stub(:connection => nil)
          eventable.__send__(:"on_connection_#{ctype}") { |ct| triggered = ct }
          eventable.pending_connection_events[:"on_#{ctype}"].first.call(ctype)
          triggered.should == ctype
        end
        it "should pass on to connection if there is a connection" do
          triggered = nil
          eventable.stub(:connection => connection)
          connection.should_receive(:"on_#{ctype}").and_yield(ctype)
          eventable.__send__(:"on_connection_#{ctype}") { |ct| triggered = ct }
          triggered.should == ctype
        end
      end
    end
  end
end
