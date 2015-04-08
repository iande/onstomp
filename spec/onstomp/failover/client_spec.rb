# -*- encoding: utf-8 -*-
require 'spec_helper'

module OnStomp::Failover
  describe Client, :failover => true do
    let(:client_options) { Hash.new }
    let(:active_client) {
      mock('active client').tap do |m|
        m.extend OnStomp::Interfaces::ClientEvents
      end
    }
    let(:client) {
      Client.new('failover:(stomp:///,stomp+ssl:///)').tap do |c|
        c.stub(:active_client => active_client)
      end
    }

    class DummyBuffer
      def initialize *args
      end
    end

    describe "initialize" do
      it "should be initialized by string" do
        c = Client.new('failover:(stomp:///,stomp+ssl:///)')
        c.uri.to_s.should == 'failover:(stomp:///,stomp+ssl:///)'
        c.hosts.should == ['stomp:///', 'stomp+ssl:///']
      end

      it "should be initialized by array" do
        real_client = OnStomp::Client.new('stomp+ssl:///')
        c = Client.new(['stomp:///', real_client])
        c.uri.to_s.should == 'failover:()'
        c.hosts.should == ['stomp:///', real_client]
      end

      it 'passes other options on to the client pool' do
        # We really only need to verify that the failover client is passing
        # the appropriate hash to the pool, because we have a spec that ensures
        # the pool is passing the options hash on to the underlying clients.
        # However, even performing this simple test requires an impressive
        # amount of legwork. This design is far too muddy.

        m_client = mock('client', on_connection_closed: "ignore me!")
        Pools::Base.should_receive(:new).with([ 'stomp:///', 'stomp+ssl:///' ], {
          ssl: { ca_file: 'ca.crt' },
          login: 'user_name'
        }).and_return([ m_client ])

        c = Client.new('failover:(stomp:///,stomp+ssl:///)', {
          buffer: 'OnStomp::Failover::DummyBuffer',
          retry_attempts: 2,
          ssl: { ca_file: 'ca.crt' },
          login: 'user_name'
        })
      end
    end

    describe ".connected?" do
      it "should be connected if it has an active client that's connected" do
        active_client.stub(:connected? => true)
        client.connected?.should be_true
      end
      it "should not be connected if it has an active client that's not connected" do
        active_client.stub(:connected? => false)
        client.connected?.should be_false
      end
      it "should not be connected if it has no active client" do
        client.stub(:active_client => nil)
        client.connected?.should be_false
      end
    end
    
    describe ".connect" do
      it "should call reconnect" do
        client.should_receive(:reconnect).and_return(true)
        client.connect.should == client
      end
      it "should raise an maximum retries error if reconnect is false" do
        client.stub(:reconnect => false)
        lambda {
          client.connect
        }.should raise_error(OnStomp::Failover::MaximumRetriesExceededError)
      end
      it "should trigger :on_failover_connect_failure if connecting raises an exception" do
        triggered = false
        client.on_failover_connect_failure { |*_| triggered = true }
        active_client.stub(:connected? => false)
        active_client.should_receive(:connect).and_return do
          active_client.stub(:connected? => true)
          raise "find yourself a big lady"
        end
        client.connect
        triggered.should be_true
      end
    end
    
    describe ".disconnect" do
      let(:connection) {
        mock('connection').tap do |m|
          m.extend OnStomp::Interfaces::ConnectionEvents
        end
      }
      let(:client_pool) {
        [active_client].tap do |m|
          m.stub(:next_client => active_client)
        end
      }
      before(:each) do
        # Get the hooks installed on our mocks
        active_client.stub(:connection => connection)
        client.stub(:client_pool => client_pool)
        client.__send__ :create_client_pool, [], {}
      end
      it "should do nothing special if there is no active client" do
        client.stub(:active_client => nil)
        client.disconnect
      end
      it "should wait until the active client is ready, then call its disconnect method" do
        active_client.stub(:connected? => false)
        active_client.stub(:connect).and_return do
          active_client.stub(:connected? => true)
        end
        client.connect
        actual_disconnect = client.method(:disconnect)
        client.stub(:disconnect).and_return do |*args|
          active_client.stub(:connected? => false)
          # Fire this off in a separate thread, as would be the real case
          t = Thread.new do
            connection.trigger_event :on_closed, active_client, connection
          end
          Thread.pass while t.alive?
          actual_disconnect.call *args
        end
        
        active_client.should_receive(:disconnect).with(:header1 => 'value 1')
        client.disconnect :header1 => 'value 1'
      end
      it "should disconnect promptly if retrying exceeds maximum attempts" do
        client.retry_attempts = 3
        client.retry_delay = 0
        active_client.stub(:connected? => false)
        active_client.stub(:connect).and_return do
          active_client.stub(:connected? => true)
        end
        client.connect
        actual_disconnect = client.method(:disconnect)
        client.stub(:disconnect).and_return do |*args|
          active_client.stub(:connect => false)
          active_client.stub(:connected? => false)
          # Fire this off in a separate thread, as would be the real case
          t = Thread.new do
            connection.trigger_event :on_closed, active_client, connection
          end
          Thread.pass while t.alive?
          actual_disconnect.call *args
        end
        client.disconnect :header1 => 'value 1'
      end
    end
    
    describe ".transmit" do
      it "should transmit on the active client if there is one" do
        active_client.should_receive(:transmit).with('test', :coming => 'home')
        client.transmit 'test', :coming => 'home'
        client.stub(:active_client => nil)
        client.transmit(mock('frame')).should be_nil
      end
    end
  end
end
