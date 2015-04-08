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

  describe "Failing on connect" do
    let(:broker) {
      TestBroker.new 10101
    }
    before :each do
      broker.start
    end
    after :each do
      broker.stop
    end

    it "raises an error when the TCP/IP connection is refused" do
      broker.stop
      client = OnStomp::Client.new('stomp://localhost:10101')
      lambda do
        client.connect
      end.should raise_error
    end

    it "raises an error if the connection is closed while writing the CONNECT frame" do
      broker.session_class = TestBroker::SessionCloseBeforeConnect
      client = OnStomp::Client.new('stomp://localhost:10101')
      lambda do
        client.connect
      end.should raise_error
    end

    it "raises an error if the connection is closed while waiting for the CONNECTED frame" do
      broker.session_class = TestBroker::SessionCloseAfterConnect
      client = OnStomp::Client.new('stomp://localhost:10101')
      lambda do
        client.connect
      end.should raise_error
    end

    it "raises an error if the connection times out before receiving a CONNECTED frame" do
      broker.session_class = TestBroker::SessionTimeoutAfterConnect
      client = OnStomp::Client.new('stomp://localhost:10101')
      client.read_timeout = 1
      lambda do
        client.connect
      end.should raise_error(OnStomp::ConnectionTimeoutError)
    end

    it "raises an error if the broker does not respond with CONNECTED" do
      broker.session_class = TestBroker::SessionBadFrameAfterConnect
      client = OnStomp::Client.new('stomp://localhost:10101')
      lambda do
        client.connect
      end.should raise_error(OnStomp::ConnectFailedError)
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
      it "should run just fine" do
        blocked_up = false
        client = OnStomp::Client.new('stomp://localhost:10101')
        client.on_connection_blocked do |*_|
          blocked_up = true
        end
        client.write_timeout = 1
        client.connect
        client.send '/queue/test', 'my message body', {
          "this:is\na \\fun\\ header" => 'blather matter'
        }
        client.send '/queue/test', encode_body("\x01\x02\x03\x04\x05\x06", 'BINARY'),
          :'content-type' => 'application/octet-stream'
        sleep 1.5
        client.send '/queue/test', encode_body("hëllo", 'ISO-8859-1')
        client.disconnect :receipt => 'rcpt-disconnect'
        broker.join
        blocked_up.should be_false
      end

      it 'should include login/passcode headers that are not empty' do
        client = OnStomp::Client.new('stomp://localhost:10101', login: 'user', passcode: 'secr3t')
        client.connect
        client.disconnect
        broker.join
        broker.frames_received.first.command.should == 'CONNECT'
        broker.frames_received.first.headers['login'].should == 'user' 
        broker.frames_received.first.headers['passcode'].should == 'secr3t'
      end

      it 'should not include login/passcode headers that are empty' do
        client = OnStomp::Client.new('stomp://localhost:10101')
        client.connect
        client.disconnect
        broker.join
        broker.frames_received.first.command.should == 'CONNECT'
        broker.frames_received.first.headers.set?('login').should == false 
        broker.frames_received.first.headers.set?('passcode').should == false
      end
      
      it "should block on write" do
        blocked_up = false
        client = OnStomp::Client.new('stomp://localhost:10101')
        client.on_connection_blocked do |*_|
          blocked_up = true
        end
        client.write_timeout = 1
        client.connect
        # Can't seem to make this happen, so we'll do the next best thing.
        con = client.connection
        def con.ready_for_write?
          false
        end
        client.send '/queue/test', 'my message body', {
          "this:is\na \\fun\\ header" => 'blather matter'
        }
        client.send '/queue/test', encode_body("\x01\x02\x03\x04\x05\x06", 'BINARY'),
            :'content-type' => 'application/octet-stream'
        sleep 1.5
        client.send '/queue/test', encode_body("hëllo", 'ISO-8859-1')
        client.disconnect
        broker.stop
        blocked_up.should be_true
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
