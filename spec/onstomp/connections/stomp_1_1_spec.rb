# -*- encoding: utf-8 -*-
require 'spec_helper'

module OnStomp::Connections
  describe Stomp_1_1 do
    let(:io) {
      mock('io')
    }
    let(:client) {
      mock('client')
    }
    let(:connection) {
      Stomp_1_1.new(io, client)
    }
    describe "ancestors" do
      it "should be a kind of Base connection" do
        connection.should be_a_kind_of(OnStomp::Connections::Base)
      end
      it "should be a kind of Stomp_1 connection" do
        connection.should be_a_kind_of(OnStomp::Connections::Stomp_1)
      end
      it "should be a kind of Heartbeating connection" do
        connection.should be_a_kind_of(OnStomp::Connections::Heartbeating)
      end
    end
    
    describe ".serializer" do
      it "should use a Stomp_1_1 serializer" do
        connection.serializer.should be_a_kind_of(OnStomp::Connections::Serializers::Stomp_1_1)
      end
    end
    
    describe ".subscribe_frame" do
      it "should automatically generate an 'id' header if one is not supplied" do
        frame = connection.subscribe_frame('/queue/test', :ack => 'client',
          :destination => '/queue/not-test')
        frame.should be_an_onstomp_frame('SUBSCRIBE', {:ack => 'client',
          :destination => '/queue/test'}, nil)
        frame.header?(:id).should be_true
      end
      it "should build a SUBSCRIBE frame" do
        connection.subscribe_frame('/queue/test', :ack => 'client-individual',
          :destination => '/queue/not-test', :id => 's-1234'
        ).should be_an_onstomp_frame('SUBSCRIBE', {:ack => 'client-individual',
          :destination => '/queue/test', :id => 's-1234'}, nil)
      end
      it "should set ack mode to auto if it is not set to client or client-individual" do
        connection.subscribe_frame('/queue/test', :ack => 'fudge!',
          :destination => '/queue/not-test', :id => 's-1234'
        ).should be_an_onstomp_frame('SUBSCRIBE', {:ack => 'auto',
          :destination => '/queue/test', :id => 's-1234'}, nil)
      end
    end
    
    describe ".ack_frame" do
      let(:message_frame) {
        OnStomp::Components::Frame.new('MESSAGE',
          :'message-id' => 'm-1234', :subscription => 's-5678')
      }
      it "should create an ACK frame for a MESSAGE frame" do
        connection.ack_frame(message_frame).should be_an_onstomp_frame('ACK',
          {:'message-id' => 'm-1234', :subscription => 's-5678'}, nil)
      end
      it "should create an ACK frame for a message id and subscription" do
        connection.ack_frame('m-5678', 's-1234').should be_an_onstomp_frame('ACK',
          {:'message-id' => 'm-5678', :subscription => 's-1234'}, nil)
      end
      it "should override the message id and subscription with headers" do
        connection.ack_frame('m-5678', 's-1234', {
          :'message-id' => 'm-1234', :subscription => 's-5678'}
        ).should be_an_onstomp_frame('ACK', {:'message-id' => 'm-1234',
          :subscription => 's-5678'}, nil)
      end
      it "should raise an error if a message-id cannot be inferred" do
        lambda {
          connection.ack_frame(nil, {:'message-id' => '', :subscription => 's-1234'})
        }.should raise_error(ArgumentError)
      end
      it "should raise an error if a subscription cannot be inferred" do
        lambda {
          connection.ack_frame('m-1234', nil, { :subscription => ''})
        }.should raise_error(ArgumentError)
      end
    end
    
    describe ".connected?" do
      it "should be connected if Base is connected and it has a pulse" do
        io.stub(:closed? => false)
        connection.stub(:pulse? => true)
        connection.connected?.should be_true
      end
      it "should not be connected if Base is not connected" do
        io.stub(:closed? => true)
        connection.stub(:pulse? => true)
        connection.connected?.should be_false
      end
      it "should not be connected if it has no pulse" do
        io.stub(:closed? => false)
        connection.stub(:pulse? => false)
        connection.connected?.should be_false
      end
    end
    
    describe ".configure" do
      let(:client_beats) { mock('client beats') }
      let(:broker_beats) { mock('broker beats') }
      let(:connected_frame) {
        mock('connected frame', :heart_beat => broker_beats).tap do |m|
          m.stub(:header?).with(:version).and_return(true)
          m.stub(:[]).with(:version).and_return('1.1')
        end
      }
      
      it "should configure heartbeating" do
        client.stub(:heartbeats => client_beats)
        connection.should_receive(:configure_heartbeating).
          with(client_beats, broker_beats)
        connection.configure(connected_frame, {})
      end
    end
    
    describe ".nack_frame" do
      let(:message_frame) {
        OnStomp::Components::Frame.new('MESSAGE',
          :'message-id' => 'm-1234', :subscription => 's-5678')
      }
      it "should create a NACK frame for a MESSAGE frame" do
        connection.nack_frame(message_frame).should be_an_onstomp_frame('NACK',
          {:'message-id' => 'm-1234', :subscription => 's-5678'}, nil)
      end
      it "should create a NACK frame for a message id and subscription" do
        connection.nack_frame('m-5678', 's-1234').should be_an_onstomp_frame('NACK',
          {:'message-id' => 'm-5678', :subscription => 's-1234'}, nil)
      end
      it "should override the message id and subscription with headers" do
        connection.nack_frame('m-5678', 's-1234', {
          :'message-id' => 'm-1234', :subscription => 's-5678'}
        ).should be_an_onstomp_frame('NACK', {:'message-id' => 'm-1234',
          :subscription => 's-5678'}, nil)
      end
      it "should raise an error if a message-id cannot be inferred" do
        lambda {
          connection.nack_frame(nil, {:'message-id' => '', :subscription => 's-1234'})
        }.should raise_error(ArgumentError)
      end
      it "should raise an error if a subscription cannot be inferred" do
        lambda {
          connection.nack_frame('m-1234', nil, { :subscription => ''})
        }.should raise_error(ArgumentError)
      end
    end
    
    describe ".heartbeat_frame" do
      it "should create a heartbeat frame (frame with no command)" do
        connection.heartbeat_frame.should be_an_onstomp_frame(nil, {}, nil)
      end
    end
  end
end
