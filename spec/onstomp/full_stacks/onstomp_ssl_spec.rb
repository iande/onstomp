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
      TestSSLBroker.new 10103
    }
    before(:each) do
      broker.start
    end
    after(:each) do
      broker.stop
    end
  
    describe "connecting with SSL options" do
      it "should connect to the broker given a CA path" do
        client = OnStomp::Client.new('stomp+ssl://localhost:10103', :ssl => {
          :ca_file => File.expand_path('../ssl/demoCA/cacert.pem', __FILE__),
          :post_connection_check => 'My Broker'
        })
        client.connect
        client.send '/queue/test', 'my message body', {
          "this:is\na \\fun\\ header" => 'blather matter'
        }
        client.send '/queue/test', encode_body("\x01\x02\x03\x04\x05\x06",'BINARY'),
          :'content-type' => 'application/octet-stream'
        client.disconnect
        broker.join
      end
      it "should fail when post connection check does not match CN" do
        client = OnStomp::Client.new('stomp+ssl://localhost:10103', :ssl => {
          :ca_file => File.expand_path('../ssl/demoCA/cacert.pem', __FILE__),
          :post_connection_check => 'Sweet Brokerage'
        })
        lambda {
          client.connect
        }.should raise_error #('hostname was not match with the server certificate')
      end
    end
  end
  describe "STOMP 1.1" do
    let(:broker) {
      TestSSLBroker.new(10103).tap do |b|
        b.session_class = TestBroker::Session11
      end
    }
    before(:each) do
      broker.start
    end
    after(:each) do
      broker.stop
    end
  
    describe "connecting with SSL options" do
      it "should connect to the broker given a CA path" do
        client = OnStomp::Client.new('stomp+ssl://localhost:10103', :ssl => {
          :ca_file => File.expand_path('../ssl/demoCA/cacert.pem', __FILE__),
          :post_connection_check => 'My Broker'
        })
        client.connect
        client.send '/queue/test', 'my message body', {
          "this:is\na \\fun\\ header" => 'blather matter'
        }
        client.send '/queue/test', encode_body("\x01\x02\x03\x04\x05\x06",'BINARY'),
          :'content-type' => 'application/octet-stream'
        client.disconnect
        broker.join
      end
      it "should fail when post connection check does not match CN" do
        client = OnStomp::Client.new('stomp+ssl://localhost:10103', :ssl => {
          :ca_file => File.expand_path('../ssl/demoCA/cacert.pem', __FILE__),
          :post_connection_check => 'Sweet Brokerage'
        })
        lambda {
          client.connect
        }.should raise_error #('hostname was not match with the server certificate')
      end
    end
  end

end
