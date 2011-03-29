# -*- encoding: utf-8 -*-
require 'spec_helper'

module OnStomp::Interfaces
  describe FrameMethods do
    let(:connection) {
      mock('connection')
    }
    let(:framer) {
      mock('framer', :connection => connection).tap do |m|
        m.extend FrameMethods
      end
    }
    let(:headers) {
      { :header1 => 'value 1' }
    }
    let(:frame) {
      mock('frame')
    }
    let(:callback) {
      lambda { }
    }
    
    describe ".send" do
      it "should transmit the result of connection.send_frame and callbacks" do
        connection.should_receive(:send_frame).with('/queue/test', 'frame body', headers).and_return(frame)
        framer.should_receive(:transmit).with(frame, { :receipt => callback })
        framer.send('/queue/test', 'frame body', headers, &callback)
      end
      it "should be aliased as .puts" do
        connection.should_receive(:send_frame).with('/queue/test', 'frame body', headers).and_return(frame)
        framer.should_receive(:transmit).with(frame, { :receipt => callback })
        framer.puts('/queue/test', 'frame body', headers, &callback)
      end
    end
    
    describe ".subscribe" do
      it "should transmit the result of connection.subscribe_frame and callbacks" do
        connection.should_receive(:subscribe_frame).with('/queue/test2', headers).and_return(frame)
        framer.should_receive(:transmit).with(frame, { :subscribe => callback })
        framer.subscribe('/queue/test2', headers, &callback)
      end
    end
    
    describe ".unsubscribe" do
      it "should transmit the result of connection.unsubscribe_frame" do
        connection.should_receive(:unsubscribe_frame).with('frame_or_id', headers).and_return(frame)
        framer.should_receive(:transmit).with(frame)
        framer.unsubscribe('frame_or_id', headers)
      end
    end
    
    describe ".begin" do
      it "should transmit the result of connection.begin_frame" do
        connection.should_receive(:begin_frame).with('tx_id', headers).and_return(frame)
        framer.should_receive(:transmit).with(frame)
        framer.begin('tx_id', headers)
      end
    end
    
    describe ".abort" do
      it "should transmit the result of connection.abort_frame" do
        connection.should_receive(:abort_frame).with('tx_id', headers).and_return(frame)
        framer.should_receive(:transmit).with(frame)
        framer.abort('tx_id', headers)
      end
    end
    
    describe ".commit" do
      it "should transmit the result of connection.commit_frame" do
        connection.should_receive(:commit_frame).with('tx_id', headers).and_return(frame)
        framer.should_receive(:transmit).with(frame)
        framer.commit('tx_id', headers)
      end
    end
    
    describe ".disconnect" do
      it "should transmit the result of connection.disconnect_frame" do
        connection.should_receive(:disconnect_frame).with(headers).and_return(frame)
        framer.should_receive(:transmit).with(frame)
        framer.disconnect(headers)
      end
    end
    
    describe ".ack" do
      it "should transmit the result of connection.ack_frame" do
        connection.should_receive(:ack_frame).with('arg1', headers, :arg2).and_return(frame)
        framer.should_receive(:transmit).with(frame)
        framer.ack('arg1', headers, :arg2)
      end
    end
    
    describe ".nack" do
      it "should transmit the result of connection.nack_frame" do
        connection.should_receive(:nack_frame).with('arg1', headers, :arg2).and_return(frame)
        framer.should_receive(:transmit).with(frame)
        framer.nack('arg1', headers, :arg2)
      end
    end
    
    describe ".beat" do
      it "should transmit the result of connection.heartbeat_frame" do
        connection.should_receive(:heartbeat_frame).and_return(frame)
        framer.should_receive(:transmit).with(frame)
        framer.beat
      end
    end
  end
end
