# -*- encoding: utf-8 -*-
require 'spec_helper'

module OnStomp
  describe Connections do
    describe ".supported" do
      it "should be 1.0 and 1.1" do
        Connections.supported.should == ['1.0', '1.1']
      end
    end
    
    describe ".select_supported" do
      it "should filter out any unsupported version" do
        Connections.select_supported(['1.9', '1.0', '2.x']).should ==
          ['1.0']
      end
      it "should be empty if none are supported" do
        Connections.select_supported(['1.5', '1.9', '1.x']).should be_empty
      end
    end
    
    describe ".connect" do
      let(:client_uri) { mock('uri', :host => 'host.domain.tld', :port => 10101) }
      let(:stomp_1_0_class) { mock('stomp 1.0 class') }
      let(:stomp_1_1_class) { mock('stomp 1.1 class') }
      let(:stomp_1_0) {
        mock('stomp 1.0', :is_a? => false, :read_timeout => 30, :write_timeout => 20).tap do |m|
          m.stub(:is_a?).with(stomp_1_0_class).and_return(true)
        end
      }
      let(:stomp_1_1) {
        mock('stomp 1.1', :is_a? => false, :read_timeout => 30, :write_timeout => 20).tap do |m|
          m.stub(:is_a?).with(stomp_1_1_class).and_return(true)
        end
      }
      let(:tcp_socket) { mock('tcp socket') }
      let(:ssl_socket) { mock('ssl socket', :sync_close= => nil, :connect => nil) }
      let(:ssl_context) { mock('ssl context') }
      let(:ssl_options) {
        {
          :post_connection_check => 'some hostname',
          :ca_file => '/path/to/ca_file.pem',
          :ca_path => '/path/to/ca_files/',
          :cert => '/path/to/client/cert.pem',
          :key => '/path/to/client/key.pem',
          :verify_mode => 'super_duper_mode',
          :ssl_version => 'SSLv3'
        }
      }
      let(:connected_frame) { mock('CONNECTED frame') }
      let(:client) {
        mock('client', :ssl => nil, :uri => client_uri)
      }
      let(:user_headers) {
        {}
      }
      let(:connect_headers) {
        {}
      }
      let(:pend_events) { mock('pending events') }
      before(:each) do
        ::TCPSocket.stub(:new => nil)
        ::OpenSSL::SSL::SSLSocket.stub(:new => nil)
        Connections::PROTOCOL_VERSIONS['1.0'] = stomp_1_0_class
        Connections::PROTOCOL_VERSIONS['1.1'] = stomp_1_1_class
      end
      after(:each) do
        Connections::PROTOCOL_VERSIONS['1.0'] = Connections::Stomp_1_0
        Connections::PROTOCOL_VERSIONS['1.1'] = Connections::Stomp_1_1
      end
      
      describe "TCP connections" do
        before(:each) do
          ::TCPSocket.should_receive(:new).with('host.domain.tld', 10101).and_return(tcp_socket)
          stomp_1_0_class.should_receive(:new).with(tcp_socket, client).and_return(stomp_1_0)
        end
        
        it "should create a 1.0 connection" do
          stomp_1_0.should_receive(:connect).and_return(['1.0', connected_frame])
          stomp_1_0.should_receive(:configure).with(connected_frame, pend_events)
          stomp_1_0.should_receive(:read_timeout=).with(5)
          stomp_1_0.should_receive(:write_timeout=).with(10)
          Connections.connect client, user_headers, connect_headers, pend_events, 5, 10
        end
        it "should create a 1.1 connection" do
          stomp_1_0.should_receive(:connect).and_return(['1.1', connected_frame])
          stomp_1_0.should_receive(:socket).and_return(tcp_socket)
          stomp_1_0.should_receive(:read_timeout=).with(10)
          stomp_1_0.should_receive(:write_timeout=).with(5)
          stomp_1_1_class.should_receive(:new).with(tcp_socket, client).and_return(stomp_1_1)
          stomp_1_1.should_receive(:configure).with(connected_frame, pend_events)
          stomp_1_1.should_receive(:read_timeout=).with(30)
          stomp_1_1.should_receive(:write_timeout=).with(20)
          Connections.connect client, user_headers, connect_headers, pend_events, 10, 5
        end
      end
      
      describe "SSL connections" do
        before(:each) do
          ::TCPSocket.should_receive(:new).with('host.domain.tld', 10101).and_return(tcp_socket)
          ::OpenSSL::SSL::SSLSocket.should_receive(:new).with(tcp_socket, ssl_context).and_return(ssl_socket)
          ::OpenSSL::SSL::SSLContext.should_receive(:new).and_return(ssl_context)
          stomp_1_0_class.should_receive(:new).with(ssl_socket, client).and_return(stomp_1_0)
        end
        
        it "should create a 1.0 connection" do
          client.stub(:ssl => ssl_options)
          stomp_1_0.should_receive(:connect).and_return(['1.0', connected_frame])
          stomp_1_0.should_receive(:configure).with(connected_frame, pend_events)
          ssl_options.each do |k, v|
            next if k == :post_connection_check
            ssl_context.should_receive(:"#{k}=").with(v)
          end
          ssl_socket.should_receive(:post_connection_check).with(ssl_options[:post_connection_check])
          stomp_1_0.should_receive(:read_timeout=).with(5)
          stomp_1_0.should_receive(:write_timeout=).with(10)
          Connections.connect client, user_headers, connect_headers, pend_events, 5, 10
        end
        it "should create a 1.1 connection" do
          client.stub(:ssl => nil)
          client_uri.stub(:onstomp_socket_type => :ssl)
          stomp_1_0.should_receive(:connect).and_return(['1.1', connected_frame])
          Connections::DEFAULT_SSL_OPTIONS.each do |k, v|
            next if k == :post_connection_check
            ssl_context.should_receive(:"#{k}=").with(v)
          end
          ssl_socket.should_receive(:post_connection_check).with(client_uri.host)
          stomp_1_0.should_receive(:socket).and_return(ssl_socket)
          stomp_1_0.should_receive(:read_timeout=).with(10)
          stomp_1_0.should_receive(:write_timeout=).with(5)
          stomp_1_1_class.should_receive(:new).with(ssl_socket, client).and_return(stomp_1_1)
          stomp_1_1.should_receive(:configure).with(connected_frame, pend_events)
          stomp_1_1.should_receive(:read_timeout=).with(30)
          stomp_1_1.should_receive(:write_timeout=).with(20)
          Connections.connect client, user_headers, connect_headers, pend_events, 10, 5
        end
      end
      
      describe "raising an OnStompError while negotiating connection" do
        it "should close the base connection in a blocking fashion" do
          Connections.stub(:create_connection).and_return(stomp_1_0)
          stomp_1_0.stub(:connect => ['1.0', connected_frame])
          Connections.stub(:negotiate_connection).and_raise OnStomp::OnStompError
          stomp_1_0.should_receive(:close).with(true)
          lambda {
            Connections.connect client, user_headers, connect_headers, pend_events, 5, 10
          }.should raise_error(OnStomp::OnStompError)
        end
      end
    end
  end
end
