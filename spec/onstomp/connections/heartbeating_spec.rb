# -*- encoding: utf-8 -*-
require 'spec_helper'

module OnStomp::Connections
  describe Heartbeating do
    let(:connection) {
      mock('connection').tap do |m|
        m.extend Heartbeating
      end
    }
    
    describe ".configure_heartbeating" do
      it "should use 0 for client beats if either side is zero" do
        connection.configure_heartbeating([0,500], [100, 300])
        connection.heartbeating.first.should == 0
        connection.configure_heartbeating([300,500], [100, 0])
        connection.heartbeating.first.should == 0
      end
      it "should use 0 for broker beats if either side is zero" do
        connection.configure_heartbeating([500,0], [100, 300])
        connection.heartbeating.last.should == 0
        connection.configure_heartbeating([300,100], [0, 500])
        connection.heartbeating.last.should == 0
      end
      it "should use the maximums for heartbeating" do
        connection.configure_heartbeating([500,700], [100, 300])
        connection.heartbeating.should == [500, 700]
      end
    end
    
    describe ".pulse?" do
      it "should not have a pulse if it has no client pulse" do
        connection.stub(:client_pulse? => false, :broker_pulse? => true)
        connection.pulse?.should be_false
      end
      it "should not have a pulse if it has no broker pulse" do
        connection.stub(:client_pulse? => true, :broker_pulse? => false)
        connection.pulse?.should be_false
      end
      it "should have a pulse if it has both a client and broker pulse" do
        connection.stub(:client_pulse? => true, :broker_pulse? => true)
        connection.pulse?.should be_true
      end
    end
    
    describe ".heartbeat_client_limit" do
      it "should be 110% of a positive client heartbeat value" do
        connection.stub(:heartbeating => [64, 0])
        connection.heartbeat_client_limit.should == 70.4
      end
      it "should be 0 if the client heartbeat value is 0" do
        connection.stub(:heartbeating => [0, 90])
        connection.heartbeat_client_limit.should == 0
      end
    end
    
    describe ".heartbeat_broker_limit" do
      it "should be 110% of a positive broker heartbeat value" do
        connection.stub(:heartbeating => [0, 32])
        connection.heartbeat_broker_limit.should == 35.2
      end
      it "should be 0 if the broker heartbeat value is 0" do
        connection.stub(:heartbeating => [90, 0])
        connection.heartbeat_broker_limit.should == 0
      end
    end
    
    describe ".client_pulse?" do
      it "should be true if client heartbeating is disabled" do
        connection.stub(:heartbeat_client_limit => 0)
        connection.client_pulse?.should be_true
      end
      it "should be true if duration since transmitted is at most client limit" do
        connection.stub(:heartbeat_client_limit => 10)
        connection.stub(:duration_since_transmitted => 1)
        connection.client_pulse?.should be_true
        connection.stub(:heartbeat_client_limit => 10)
        connection.stub(:duration_since_transmitted => 10)
        connection.client_pulse?.should be_true
      end
      it "should be false if duration since transmitted is greater than client limit" do
        connection.stub(:heartbeat_client_limit => 10)
        connection.stub(:duration_since_transmitted => 11)
        connection.client_pulse?.should be_false
      end
    end
    
    describe ".broker_pulse?" do
      it "should be true if broker heartbeating is disabled" do
        connection.stub(:heartbeat_broker_limit => 0)
        connection.broker_pulse?.should be_true
      end
      it "should be true if duration since transmitted is at most broker limit" do
        connection.stub(:heartbeat_broker_limit => 10)
        connection.stub(:duration_since_received => 1)
        connection.broker_pulse?.should be_true
        connection.stub(:heartbeat_broker_limit => 10)
        connection.stub(:duration_since_received => 10)
        connection.broker_pulse?.should be_true
      end
      it "should be false if duration since received is greater than broker limit" do
        connection.stub(:heartbeat_broker_limit => 10)
        connection.stub(:duration_since_received => 11)
        connection.broker_pulse?.should be_false
      end
    end
  end
end
