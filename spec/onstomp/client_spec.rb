# -*- encoding: utf-8 -*-
require 'spec_helper'

module OnStomp
  describe Client do
    let(:client_uri) { "stomp:///" }
    let(:client_options) { Hash.new }
    let(:client) {
      Client.new client_uri, client_options
    }
    let(:processor) {
      mock('processor')
    }
    let(:processor_class) {
      mock('processor class', :new => processor)
    }
    let(:connection) {
      mock('connection')
    }
    let(:frame) {
      mock('frame')
    }
    let(:headers) {
      mock('headers')
    }
    
    let(:frame_method_interface) { client }
    it_should_behave_like "frame method interfaces"
    
    describe "configuration" do
      it "should provide some defaults" do
        client.versions.should == ['1.0', '1.1']
        client.host.should == 'localhost'
        client.login.should == ''
        client.passcode.should == ''
        client.heartbeats.should == [0, 0]
        client.write_timeout.should == 120
        client.read_timeout.should == 120
        client.processor.should == OnStomp::Components::ThreadedProcessor
      end
      it "should be configurable by options" do
        client_options[:versions] = ['1.1']
        client_options[:heartbeats] = [90, 110]
        client_options[:host] = 'my broker host'
        client_options[:login] = 'my login'
        client_options[:passcode] = 'sup3r s3cr3t'
        client_options[:processor] = processor_class
        client_options[:write_timeout] = 50
        client_options[:read_timeout] = 70
        client_options[:ssl] = { :cert_path => '/path/to/certs' }
        client.versions.should == ['1.1']
        client.heartbeats.should == [90, 110]
        client.host.should == 'my broker host'
        client.login.should == 'my login'
        client.passcode.should == 'sup3r s3cr3t'
        client.processor.should == processor_class
        client.write_timeout.should == 50
        client.read_timeout.should == 70
        client.ssl.should == { :cert_path => '/path/to/certs' }
      end
      it "should be configurable by query" do
        client_uri << '?versions=1.0'
        client_uri << '&heartbeats=80&heartbeats=210'
        client_uri << '&host=query%20host'
        client_uri << '&login=query%20login'
        client_uri << '&passcode=qu3ry%20s3cr3t'
        client_uri << '&processor=OnStomp::Connections'
        client_uri << '&write_timeout=30'
        client_uri << '&read_timeout=50'
        client.versions.should == ['1.0']
        client.heartbeats.should == [80, 210]
        client.host.should == 'query host'
        client.login.should == 'query login'
        client.passcode.should == 'qu3ry s3cr3t'
        client.write_timeout.should == 30
        client.read_timeout.should == 50
        client.processor.should == OnStomp::Connections
      end
      it "should be configurable through parts of the URI" do
        client_uri.replace("stomp://uzer:s3cr3t@host.domain.tld")
        client.host.should == 'host.domain.tld'
        client.login.should == 'uzer'
        client.passcode.should == 's3cr3t'
      end
      it "should prefer option hash over query over uri attributes" do
        client_uri.replace("stomp://uzer:s3cr3t@host.domain.tld?host=query%20host&passcode=qu3ry%20s3cr3t&login=query%20login")
        client_options[:login] = 'my login'
        client.host.should == 'query host'
        client.login.should == 'my login'
        client.passcode.should == 'qu3ry s3cr3t'
      end
    end
    
    describe ".initialize" do
      it "should initialize from a string uri" do
        uri = Client.new('stomp://host.domain.tld:10101').uri
        uri.should be_a_kind_of(::URI)
        uri.host.should == 'host.domain.tld'
        uri.port.should == 10101
        uri.scheme.should == 'stomp'
      end
      it "should initialize with a URI uri" do
        uri = ::URI.parse('stomp://host.domain.tld:10101')
        Client.new(uri).uri.should == uri
      end
    end
    
    describe ".connect" do
      let(:pending_events) {
        mock('pending events')
      }
      before(:each) do
        client.stub(:processor => processor_class)
      end
      it "should create a connection and start the processor" do
        OnStomp::Connections.should_receive(:connect).with(client, headers,
          { :'accept-version' => '1.1', :host => 'my host',
            :'heart-beat' => '30,110', :login => 'my login',
            :passcode => 's3cr3t' }, pending_events, 30, 50).and_return(connection)
        processor.should_receive(:stop)
        processor.should_receive(:start)
        client.stub(:pending_connection_events => pending_events)
        client.versions = '1.1'
        client.host = 'my host'
        client.login = 'my login'
        client.passcode = 's3cr3t'
        client.heartbeats = [30,110]
        client.read_timeout = 30
        client.write_timeout = 50
        client.connect(headers)
        client.connection.should == connection
      end
    end
    
    describe ".disconnect_with_flush" do
      before(:each) do
        client.stub(:processor => processor_class)
      end
      it "should call disconnect_without_flush and join the processor" do
        processor.should_receive(:prepare_to_close)
        processor.should_receive(:join)
        client.should_receive(:disconnect_without_flush).with(headers).and_return(frame)
        client.disconnect_with_flush(headers).should == frame
      end
    end
    
    describe ".connected?" do
      it "should not be connected if there is no connect" do
        client.should_not be_connected
      end
      it "should not be connected if the connection is not connected" do
        client.stub(:connection => connection)
        connection.stub(:connected? => false)
        client.should_not be_connected
      end
      it "should be connected if the connection exists and is connected" do
        client.stub(:connection => connection)
        connection.stub(:connected? => true)
        client.should be_connected
      end
    end
    
    describe ".close" do
      before(:each) do
        client.stub(:connection => connection)
      end
      it "should close the connection and clear all receipts and subscriptions" do
        client.should_receive(:clear_receipts)
        client.should_receive(:clear_subscriptions)
        connection.should_receive(:close)
        client.__send__ :close
      end
    end
    
    describe ".close!" do
      before(:each) do
        client.stub(:processor => processor_class)
      end
      it "should call close and stop the processor" do
        client.should_receive(:close)
        processor.should_receive(:stop)
        client.close!
      end
    end
    
    describe ".transmit" do
      let(:callbacks) {
        { :subscribe => 'subscribe', :receipt => 'receipt' }
      }
      before(:each) do
        client.stub(:connection => connection)
      end
      it "should register any callbacks, trigger events, write and return the frame" do
        client.should_receive(:trigger_before_transmitting).with(frame)
        client.should_receive(:add_subscription).with(frame, 'subscribe')
        client.should_receive(:add_receipt).with(frame, 'receipt')
        connection.should_receive(:write_frame_nonblock).with(frame)
        client.transmit(frame, callbacks).should == frame
      end
    end
    
    describe ".dispatch_transmitted" do
      it "should trigger the after transmitting event" do
        client.should_receive(:trigger_after_transmitting).with(frame)
        client.dispatch_transmitted(frame)
      end
    end
    
    describe ".dispatch_received" do
      it "should trigger the before and after receiving events" do
        client.should_receive(:trigger_before_receiving).with(frame)
        client.should_receive(:trigger_after_receiving).with(frame)
        client.dispatch_received(frame)
      end
    end
    
    describe "on_disconnect" do
      it "should call close if there is no receipt header on the frame" do
        client.should_receive(:close)
        client.trigger_after_receiving OnStomp::Components::Frame.new('DISCONNECT')
      end
      it "should not call close if a receipt header is present" do
        client.should_not_receive(:close)
        client.trigger_after_receiving OnStomp::Components::Frame.new('DISCONNECT', :receipt => 'r-1234')
      end
    end
    
    describe ".versions" do
      it "should select only those versions that are supported" do
        client.versions = ['1.9', '1.1', '2.5', '1.0', '82']
        client.versions.should == ['1.0', '1.1']
      end
      it "should raise an unsupported protocol version error if no versions are viable" do
        lambda {
          client.versions = ['1.3', '8.x']
        }.should raise_error(OnStomp::UnsupportedProtocolVersionError)
      end
    end
    
    describe ".heartbeats" do
      it "should convert values to non-negative integers" do
        client.heartbeats = ['-9100', '31313']
        client.heartbeats.should == [0, 31313]
      end
    end
    
    describe ".processor" do
      it "should convert the processor to a class/module" do
        client.processor = '::Module'
        client.processor.should == Module
      end
    end
    
    describe ".login" do
      it "should convert to a string" do
        client.login = 314.3
        client.login.should == '314.3'
      end
    end
    
    describe ".passcode" do
      it "should convert to a string" do
        client.passcode = 42
        client.passcode.should == '42'
      end
    end
    
    describe ".host" do
      it "should convert to a string" do
        client.host = :hostname
        client.host.should == 'hostname'
      end
    end
  end
end
