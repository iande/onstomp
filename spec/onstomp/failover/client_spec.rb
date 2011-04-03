# -*- encoding: utf-8 -*-
require 'spec_helper'

module OnStomp::Failover
  describe Client, :failover => true do
    let(:active_client) {
      mock('active client')
    }
    let(:client) {
      Client.new('failover:(stomp:///,stomp+ssl:///)').tap do |c|
        c.stub(:active_client => active_client)
      end
    }
    describe ".connected?" do
      it "should be connected if it has an active client that's connected" do
        active_client.stub(:connected? => true)
        client.connected?.should be_true
      end
      it "should not be connected if it has an active client that's not connected" do
        active_client.stub(:connected? => false)
        client.connected?.should be_false
      end
      it "should not be connected if it has no active client" do
        client.stub(:active_client => nil)
        client.connected?.should be_false
      end
    end
    
    describe ".transmit" do
      it "should transmit on the active client if there is one" do
        active_client.should_receive(:transmit).with('test', :coming => 'home')
        client.transmit 'test', :coming => 'home'
        client.stub(:active_client => nil)
        client.transmit(mock('frame')).should be_nil
      end
    end
  end
end
