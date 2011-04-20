# -*- encoding: utf-8 -*-
require 'spec_helper'
require File.expand_path('../test_broker', __FILE__)

describe OnStomp::Failover, "full stack test", :fullstack => true, :failover => true do
  let(:brokers) {
    [TestBroker.new(10102),
      TestBroker.new(10103)]
  }
  before(:each) do
    brokers.each &:start
  end
  after(:each) do
    brokers.each &:stop
  end
  
  describe "failing over with a Written buffer" do
    # We wrote [stomp://localhost:10102]: CONNECT / {:"accept-version"=>"1.0,1.1", :host=>"localhost", :"heart-beat"=>"0,0", :login=>"", :passcode=>""}
    # We wrote [stomp://localhost:10102]: SEND / {:"x-onstomp-real-client"=>"2156558740", :destination=>"/queue/onstomp/failover/test", :"content-length"=>"22"}
    # We wrote [stomp://localhost:10102]: BEGIN / {:"x-onstomp-real-client"=>"2156558740", :transaction=>"t-1234"}
    # We wrote [stomp://localhost:10102]: SEND / {:transaction=>"t-1234", :"x-onstomp-real-client"=>"2156558740", :destination=>"/queue/onstomp/failover/test", :"content-length"=>"15"}
    # We wrote [stomp://localhost:10102]: SUBSCRIBE / {:id=>"1", :"x-onstomp-real-client"=>"2156558740", :ack=>"auto", :destination=>"/queue/onstomp/failover/test"}
    # We wrote [stomp://localhost:10102]: SEND / {:"x-onstomp-real-client"=>"2156558740", :destination=>"/queue/onstomp/failover/test", :"content-length"=>"18"}
    # We wrote [stomp://localhost:10103]: CONNECT / {:"accept-version"=>"1.0,1.1", :host=>"localhost", :"heart-beat"=>"0,0", :login=>"", :passcode=>""}
    # We wrote [stomp://localhost:10103]: DISCONNECT / {:"x-onstomp-real-client"=>"2156556660"}
    # Received: ["CONNECT", "SEND", "BEGIN", "SEND", "SUBSCRIBE"]We wrote [stomp://localhost:10103]: BEGIN / {:"x-onstomp-real-client"=>"2156558740", :transaction=>"t-1234", :"x-onstomp-failover-replay"=>"1"}
    # 
    # Transmitted: ["CONNECTED"]
    # Received: ["CONNECT", "DISCONNECT"]
    # Transmitted: ["CONNECTED"]
    # 
    it "should failover" do
      # Occasionally generates: ["CONNECT", "DISCONNECT", "BEGIN", "SEND", "SUBSCRIBE", "SEND", "COMMIT"]
      committed = false
      brokers.first.kill_on_command 'SUBSCRIBE'
      killed = false
      
      client = OnStomp::Failover::Client.new('failover:(stomp://localhost:10102,stomp://localhost:10103)')
      client.on_subscribe do |s, rc|
        # This frame will almost always get written to the first broker before the hangup occurs
        client.send '/queue/onstomp/failover/test', 'are you receiving?',
          :'x-onstomp-real-client' => rc.uri
      end
      
      client.connect
      client.send '/queue/onstomp/failover/test', '4-3-2-1 Earth Below Me',
        :'x-onstomp-real-client' => client.active_client.uri
      client.begin 't-1234', :'x-onstomp-real-client' => client.active_client.uri
      client.send '/queue/onstomp/failover/test', 'hello major tom',
        :transaction => 't-1234', :'x-onstomp-real-client' => client.active_client.uri
      client.subscribe('/queue/onstomp/failover/test', :'x-onstomp-real-client' => client.active_client.uri) do |m|
      end
      Thread.pass while client.connected?
      
      client.send '/queue/onstomp/failover/test', 'Are you receiving?',
        :'x-onstomp-real-client' => client.active_client.uri
      sub = client.subscribe('/queue/onstomp/failover/test2', :'x-onstomp-real-client' => client.active_client.uri) do |m|
      end
      client.unsubscribe sub, :'x-onstomp-real-client' => client.active_client.uri
      client.commit 't-1234', :'x-onstomp-real-client' => client.active_client.uri
      #Thread.pass until client.connected?
      client.disconnect :'x-onstomp-real-client' => client.active_client.uri
      brokers.each(&:join)
      brokers.first.frames_received.map(&:command).should == ["CONNECT", "SEND", "BEGIN", "SEND", "SUBSCRIBE"]
      brokers.last.frames_received.map(&:command).should == ["CONNECT", "BEGIN", "SEND", "SUBSCRIBE", "SEND", "COMMIT", "SEND", "DISCONNECT"]
    end
  end
  describe "failing over with a Receipts buffer" do
    it "should failover" do
      committed = false
      killed = false
      brokers.first.kill_on_command 'SUBSCRIBE'
      
      client = OnStomp::Failover::Client.new('failover:(stomp://localhost:10102,stomp://localhost:10103)',
        :buffer => OnStomp::Failover::Buffers::Receipts)
      client.on_subscribe do |s, rc|
        # This frame will get written, but the broker will hang up before
        # a RECEIPT is given, so it will get repeated
        client.send '/queue/onstomp/failover/test', 'are you receiving?',
          :'x-onstomp-real-client' => rc.uri
      end
      
      client.connect
      client.send '/queue/onstomp/failover/test', '4-3-2-1 Earth Below Me',
        :'x-onstomp-real-client' => client.active_client.uri
      client.begin 't-1234', :'x-onstomp-real-client' => client.active_client.uri
      client.send '/queue/onstomp/failover/test', 'hello major tom',
        :transaction => 't-1234', :'x-onstomp-real-client' => client.active_client.uri
      client.subscribe('/queue/onstomp/failover/test', :'x-onstomp-real-client' => client.active_client.uri) do |m|
      end
      Thread.pass while client.connected?
      
      client.send '/queue/onstomp/failover/test', 'Are you receiving?',
        :'x-onstomp-real-client' => client.active_client.uri
      sub = client.subscribe('/queue/onstomp/failover/test2', :'x-onstomp-real-client' => client.active_client.uri) do |m|
      end
      client.unsubscribe sub, :'x-onstomp-real-client' => client.active_client.uri
      client.commit 't-1234', :'x-onstomp-real-client' => client.active_client.uri
      #Thread.pass until client.connected?
      client.disconnect :'x-onstomp-real-client' => client.active_client.uri
      brokers.each(&:join)
      brokers.first.frames_received.map(&:command).should == ["CONNECT", "SEND", "BEGIN", "SEND", "SUBSCRIBE"]
      brokers.last.frames_received.map(&:command).should == ["CONNECT", "SEND", "BEGIN", "SEND", "SUBSCRIBE", "SEND", "SEND", "COMMIT", "SEND", "DISCONNECT"]
    end
  end
end
