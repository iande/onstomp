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
      brokers.first.kill_on_command 'SUBSCRIBE'
      brokers.last.accept_delay = 1
      
      client = OnStomp::Failover::Client.new('failover:(stomp://localhost:10102,stomp://localhost:10103)')
      client.on_subscribe do |s, rc|
        # This frame will almost always get written to the first broker before the hangup occurs
        client.send '/queue/onstomp/failover/test', 'are you receiving?'
      end
      
      client.connect
      client.send '/queue/onstomp/failover/test', '4-3-2-1 Earth Below Me'
      client.begin 't-1234'
      client.send '/queue/onstomp/failover/test', 'hello major tom',
        :transaction => 't-1234'
      client.subscribe('/queue/onstomp/failover/test') do |m|
      end
      Thread.pass while client.connected?
      
      client.send '/queue/onstomp/failover/test', 'Are you receiving?'
      sub = client.subscribe('/queue/onstomp/failover/test2') do |m|
      end
      client.unsubscribe sub
      client.commit 't-1234'

      # Need to ensure that the DISCONNECT frame was actually received by
      # the broker
      client.disconnect :receipt => 'rcpt-disconnect'
      brokers.each(&:join)
      brokers.first.frames_received.map(&:command).should == ["CONNECT", "SEND", "BEGIN", "SEND", "SUBSCRIBE"]
      # The reason there is only one SUBSCRIBE and no UNSUBSCRIBE is that
      # the pair will cancel out before the connection has been re-established.
      brokers.last.frames_received.map(&:command).should == ["CONNECT", "BEGIN", "SEND", "SUBSCRIBE", "SEND", "COMMIT", "SEND", "DISCONNECT"]
    end
  end

  describe "failing over with a Receipts buffer" do
    it "should failover" do
      brokers.first.kill_on_command 'SUBSCRIBE'
      brokers.last.accept_delay = 1
      
      client = OnStomp::Failover::Client.new('failover:(stomp://localhost:10102,stomp://localhost:10103)',
        :buffer => OnStomp::Failover::Buffers::Receipts)
      check_for_maybes = []
      client.after_transmitting do |f, c, *_|
        #puts "Sending: #{f.command} to #{c.uri}"
        if c.uri.to_s == 'stomp://localhost:10102' && f.headers?(:receipt,:may_be_receipted)
          check_for_maybes << f
        end
      end
      client.on_receipt do |r, c, *_|
        if c.uri.to_s == 'stomp://localhost:10102'
          check_for_maybes.reject! { |f| f[:receipt] == r[:'receipt-id'] }
        end
      end
      client.on_subscribe do |s, *_|
        # This frame will get written, but the broker will hang up before
        # a RECEIPT is given, so it will get repeated
        client.send '/queue/onstomp/failover/test', 'are you receiving?'
      end
      
      client.connect
      client.send '/queue/onstomp/failover/test', '4-3-2-1 Earth Below Me',
        :may_be_receipted => '1'
      client.begin 't-1234'
      client.send '/queue/onstomp/failover/test', 'hello major tom',
        :transaction => 't-1234'
      client.subscribe('/queue/onstomp/failover/test') do |m|
      end
      Thread.pass while client.connected?
      
      client.send '/queue/onstomp/failover/test', 'Are you receiving?'
      sub = client.subscribe('/queue/onstomp/failover/test2') do |m|
      end
      client.unsubscribe sub
      client.commit 't-1234'

      # Need to ensure that the DISCONNECT frame was actually received by
      # the broker
      client.disconnect :receipt => 'rcpt-disconnect'
      brokers.each(&:join)
      may_be_present = check_for_maybes.map(&:command)
      # The reason there is only one SUBSCRIBE and no UNSUBSCRIBE is that
      # the pair will cancel out before the connection has been re-established.
      brokers.first.frames_received.map(&:command).should == ["CONNECT", "SEND", "BEGIN", "SEND", "SUBSCRIBE"]
      brokers.last.frames_received.map(&:command).should == (["CONNECT"] +
        may_be_present + ["BEGIN", "SEND", "SUBSCRIBE", "SEND", "SEND", "COMMIT", "SEND", "DISCONNECT"])
    end
  end
end
