# -*- encoding: utf-8 -*-
require 'spec_helper'
require File.expand_path('../test_broker', __FILE__)

describe OnStomp::Failover, "full stack test", :fullstack => true, :failover => true do
  let(:broker) {
    TestBroker.new
  }
  before(:each) do
    broker.start
  end
  after(:each) do
    broker.stop
  end
  
  describe "failing over" do
    it "should do something worthwhile" do
      committed = false
      killed = false
      
      client = OnStomp::Failover::Client.new('failover:(stomp:///,stomp://localhost)')      
      client.on_commit do |c|
        committed = true
      end
      client.on_subscribe do |s, rc|
        broker.kill_sessions unless killed
        killed = true
        client.send '/queue/onstomp/failover/test', 'are you receiving?',
          :'x-onstomp-real-client' => rc.object_id
      end
      
      client.connect
      client.send '/queue/onstomp/failover/test', '4-3-2-1 Earth Below Me',
        :'x-onstomp-real-client' => client.active_client.object_id
      client.begin 't-1234', :'x-onstomp-real-client' => client.active_client.object_id
      client.send '/queue/onstomp/failover/test', 'hello major tom',
        :transaction => 't-1234', :'x-onstomp-real-client' => client.active_client.object_id
      client.subscribe('/queue/onstomp/failover/test', :'x-onstomp-real-client' => client.active_client.object_id) do |m|
      end
      Thread.pass while client.connected?
      
      client.send '/queue/onstomp/failover/test', 'Are you receiving?',
        :'x-onstomp-real-client' => client.active_client.object_id
      sub = client.subscribe('/queue/onstomp/failover/test2', :'x-onstomp-real-client' => client.active_client.object_id) do |m|
      end
      client.unsubscribe sub, :'x-onstomp-real-client' => client.active_client.object_id
      client.commit 't-1234', :'x-onstomp-real-client' => client.active_client.object_id
      
      client.disconnect :'x-onstomp-real-client' => client.active_client.object_id
      broker.join
      killed.should be_true
      committed.should be_true
    end
  end
end
