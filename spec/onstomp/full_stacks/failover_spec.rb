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
      client = OnStomp::Failover::Client.new('failover:(stomp:///)')
      client.on_subscribe do |s|
        broker.kill_sessions
        client.send '/queue/onstomp/failover/test', 'floating, weightless'
      end
      
      client.connect
      client.send '/queue/onstomp/failover/test', '4-3-2-1 Earth Below Me'
      client.subscribe('/queue/onstomp/failover/test') do |m|
        $stdout.puts "Got a message: #{m.body}"
      end
      Thread.pass until broker.sessions.empty?
      client.send '/queue/onstomp/failover/test', 'Are you receiving?'
      sub = client.subscribe('/queue/onstomp/failover/test2') do |m|
      end
      Thread.pass while broker.sessions.empty?
      client.unsubscribe sub
      Thread.pass until client.connected?
      client.disconnect
      Thread.pass while client.connected?
      broker.join
    end
  end
end
