# -*- encoding: utf-8 -*-
require 'spec_helper'
require File.expand_path('../test_broker', __FILE__)

describe OnStomp::OpenURI, "full stack test", :fullstack => true, :openuri => true do
  let(:broker) {
    TestBroker.new 10101
  }
  before(:each) do
    broker.start
  end
  after(:each) do
    broker.stop
  end
  
  describe "opening URIs" do
    it "should deliver some SEND frames" do
      open("stomp://localhost:10101/queue/onstomp/open-uri/test") do |c|
        c.send "Test Message 1"
        c.send "Another Test Message"
      end
      broker.join
      broker.bodies_for("/queue/onstomp/open-uri/test").should ==
        [ "Test Message 1", "Another Test Message" ]
    end
    
    it "should receive the some MESSAGE frames" do
      open("stomp://localhost:10101/queue/onstomp/open-uri/test") do |c|
        c.send "Test Message 1"
        c.send "Another Test Message"
        c.send "Last Message"
        
        c.first.body.should == "Test Message 1"
        c.first(2).map { |m| m.body }.should ==
          [ "Another Test Message", "Last Message" ]
      end
      broker.join
    end
  end
end
