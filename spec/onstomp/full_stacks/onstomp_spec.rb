# -*- encoding: utf-8 -*-
require 'spec_helper'
require File.expand_path('../test_broker', __FILE__)

describe OnStomp::Client, "full stack test (stomp+ssl:)", :fullstack => true do
  def encode_body body, encoding
    if RUBY_VERSION >= '1.9'
      body.encode(encoding)
    else
      body
    end
  end
  
  describe "STOMP 1.0" do
    let(:broker) {
      TestBroker.new 10101
    }
    before(:each) do
      broker.start
    end
    after(:each) do
      broker.stop
    end
  
    describe "connecting" do
      it "should connect to the broker given a CA path" do
        client = OnStomp::Client.new('stomp://localhost:10101')
        client.connect
        client.send '/queue/test', 'my message body', {
          "this:is\na \\fun\\ header" => 'blather matter'
        }
        client.send '/queue/test', encode_body("\x01\x02\x03\x04\x05\x06", 'BINARY'),
          :'content-type' => 'application/octet-stream'
        client.disconnect
        broker.join
      end
    end
  end
  describe "STOMP 1.1" do
    let(:broker) {
      TestBroker.new(10101).tap do |b|
        b.session_class = TestBroker::Session11
      end
    }
    before(:each) do
      broker.start
    end
    after(:each) do
      broker.stop
    end
  
    describe "connecting" do
      it "should connect to the broker given a CA path" do
        client = OnStomp::Client.new('stomp://localhost:10101')
        client.connect
        client.send '/queue/test', 'my message body', {
          "this:is\na \\fun\\ header" => 'blather matter'
        }
        client.send '/queue/test', encode_body("\x01\x02\x03\x04\x05\x06", 'BINARY'),
          :'content-type' => 'application/octet-stream'
        client.disconnect
        broker.join
      end
    end
  end

end
