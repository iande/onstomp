# -*- encoding: utf-8 -*-
require 'spec_helper'

module OnStomp::Connections
  describe Stomp_1_0 do
    let(:io) {
      mock('io')
    }
    let(:client) {
      mock('client')
    }
    let(:connection) {
      Stomp_1_0.new(io, client)
    }
    describe "ancestors" do
      it "should be a kind of Base connection" do
        connection.should be_a_kind_of(OnStomp::Connections::Base)
      end
      it "should be a kind of Stomp_1 connection" do
        connection.should be_a_kind_of(OnStomp::Connections::Stomp_1)
      end
    end
    
    describe ".serializer" do
      it "should use a Stomp_1_0 serializer" do
        connection.serializer.should be_a_kind_of(OnStomp::Connections::Serializers::Stomp_1_0)
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
        connection.subscribe_frame('/queue/test', :ack => 'auto',
          :destination => '/queue/not-test', :id => 's-1234'
        ).should be_an_onstomp_frame('SUBSCRIBE', {:ack => 'auto',
          :destination => '/queue/test', :id => 's-1234'}, nil)
      end
      it "should set ack mode to auto if it is not set to client" do
        connection.subscribe_frame('/queue/test', :ack => 'fudge!',
          :destination => '/queue/not-test', :id => 's-1234'
        ).should be_an_onstomp_frame('SUBSCRIBE', {:ack => 'auto',
          :destination => '/queue/test', :id => 's-1234'}, nil)
      end
    end
    
    describe ".ack_frame" do
      let(:message_frame) {
        OnStomp::Components::Frame.new('MESSAGE', :'message-id' => 'm-1234')
      }
      it "should create an ack frame for a MESSAGE frame" do
        connection.ack_frame(message_frame).should be_an_onstomp_frame('ACK',
          {:'message-id' => 'm-1234'}, nil)
      end
      it "should create an ack frame for a message id" do
        connection.ack_frame('m-5678').should be_an_onstomp_frame('ACK',
          {:'message-id' => 'm-5678'}, nil)
      end
      it "should override the supplied message id with a 'message-id' header" do
        connection.ack_frame('m-5678', {
          :'message-id' => 'm-1234'}
        ).should be_an_onstomp_frame('ACK', {:'message-id' => 'm-1234'}, nil)
      end
      it "should raise an exception if a message-id cannot be inferred" do
        lambda {
          connection.ack_frame(nil, {:'message-id' => ''})
        }.should raise_error(ArgumentError)
      end
    end
  end
end
