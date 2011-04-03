# -*- encoding: utf-8 -*-
require 'spec_helper'

module OnStomp::Failover
  describe FailoverEvents, :failover => true do
    let(:events) {
      mock('events', :active_client => nil).tap do |m|
        m.extend FailoverEvents
      end
    }
    let(:client_pool) {
      [mock('client 1'), mock('client 2')]
    }
    describe "client events" do
      before(:each) do
        events.stub(:client_pool => client_pool)
      end
      (OnStomp::Interfaces::ClientEvents.event_methods +
        [:on_connection_established, :on_connection_died,
          :on_connection_terminated, :on_connection_closed]).each do |meth|
        it "should bind #{meth} to each client" do
          client_pool.each { |c| c.should_receive(meth) }
          events.__send__(meth) { |*_| true }
        end
      end
    end
    
    describe "failover events" do
      [:before, :after].each do |pref|
        it "should have an event :#{pref}_failover_retry" do
          triggered = false
          events.send(:"#{pref}_failover_retry") { |*_| triggered = true }
          events.trigger_failover_retry pref, 1
          triggered.should be_true
        end
      end
      
      [:connect_failure, :retries_exceeded,
        :lost, :connected].each do |ev|
        it "should have an event :on_failover_#{ev}" do
          triggered = false
          events.send(:"on_failover_#{ev}") { |*_| triggered = true }
          events.trigger_failover_event ev, :on
          triggered.should be_true
        end
      end
    end
  end
end
