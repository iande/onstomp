# -*- encoding: utf-8 -*-
require 'spec_helper'

module OnStomp::Connections
  describe Stomp_1 do
    let(:connection) {
      mock('connection').tap do |m|
        m.extend Stomp_1
      end
    }
    
    describe ".connect_frame" do
      it "should build a CONNECT frame" do
        connection.connect_frame({:header1 => 'value 1',
          :header2 => 'value 2'}, {:header1 => '', :header2 => 'value 22',
          :header3 => 'value 3'}
        ).should be_an_onstomp_frame('CONNECT', {:header1 => 'value 1',
          :header2 => 'value 22', :header3 => 'value 3'}, nil)
      end
    end
    
    describe ".send_frame" do
      it "should build a SEND frame" do
        connection.send_frame('/queue/test', 'body of message',
          {:header1 => 'value 1', :destination => '/queue/not-test'}
        ).should be_an_onstomp_frame('SEND', {:header1 => 'value 1',
          :destination => '/queue/test'}, 'body of message')
      end
    end
    
    describe ".begin_frame" do
      it "should build a BEGIN frame" do
        connection.begin_frame('tx-1234', {:transaction => 'tx-5678',
          :header1 => 'value 1'}
        ).should be_an_onstomp_frame('BEGIN', {:header1 => 'value 1',
          :transaction => 'tx-1234'}, nil)
      end
    end
    
    describe ".commit_frame" do
      it "should build a COMMIT frame" do
        connection.commit_frame('tx-1234', {:transaction => 'tx-5678',
          :header1 => 'value 1'}
        ).should be_an_onstomp_frame('COMMIT', {:header1 => 'value 1',
          :transaction => 'tx-1234'}, nil)
      end
    end
    
    describe ".abort_frame" do
      it "should build an ABORT frame" do
        connection.abort_frame('tx-1234', {:transaction => 'tx-5678',
          :header1 => 'value 1'}
        ).should be_an_onstomp_frame('ABORT', {:header1 => 'value 1',
          :transaction => 'tx-1234'}, nil)
      end
    end
    
    describe ".disconnect_frame" do
      it "should build a DISCONNECT frame" do
        connection.disconnect_frame({:receipt => 'r-5678',
          :header1 => 'value 1'}
        ).should be_an_onstomp_frame('DISCONNECT', {:header1 => 'value 1',
          :receipt => 'r-5678'}, nil)
      end
    end
    
    describe ".unsubscribe_frame" do
      it "should build an UNSUBSCRIBE frame from a SUBSCRIBE frame" do
        subscribe_frame = OnStomp::Components::Frame.new('SUBSCRIBE',
          :id => 's-1234', :ack => 'auto')
        unsubscribe_frame = connection.unsubscribe_frame(subscribe_frame,
          :header1 => 'value 1')
        unsubscribe_frame.should be_an_onstomp_frame('UNSUBSCRIBE',
          {:header1 => 'value 1', :id => 's-1234'}, nil)
      end
      it "should build an UNSUBSCRIBE frame from an id" do
        connection.unsubscribe_frame('s-1234',
          :header1 => 'value 1'
        ).should be_an_onstomp_frame('UNSUBSCRIBE',
          {:header1 => 'value 1', :id => 's-1234'}, nil)
      end
      it "should use a supplied ID header over the supplied id" do
        connection.unsubscribe_frame('s-1234',
          :header1 => 'value 1', :id => 's-5678'
        ).should be_an_onstomp_frame('UNSUBSCRIBE',
          {:header1 => 'value 1', :id => 's-5678'}, nil)
      end
      it "should raise an error if no id header can be inferred" do
        lambda {
          connection.unsubscribe_frame(nil,
            :header1 => 'value 1', :id => '')
        }.should raise_error(ArgumentError)
      end
    end
  end
end
