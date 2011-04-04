# -*- encoding: utf-8 -*-
require 'spec_helper'

module OnStomp::Failover::Buffers
  describe Receipts, :failover => true do
    let(:clients) {
      ['client 1', 'client 2', 'client 3'].map do |c|
        mock(c).tap do |m|
          m.extend OnStomp::Interfaces::ClientEvents
        end
      end
    }
    let(:active_client) { clients.first }
    let(:failover) {
      mock('failover client', :client_pool => clients,
        :active_client => active_client).tap do |m|
        m.extend OnStomp::Failover::FailoverEvents
      end
    }
    let(:buffer) {
      Receipts.new failover
    }
    let(:partial_transaction) {
      [
        OnStomp::Components::Frame.new('BEGIN', :transaction => 't-1234'),
        OnStomp::Components::Frame.new('SEND', {:transaction => 't-1234'}, 'message 1'),
        OnStomp::Components::Frame.new('SEND', {:transaction => 't-1234'}, 'message 2'),
        OnStomp::Components::Frame.new('ACK', {:transaction => 't-1234',
          :'message-id' => 'm-99991'}),
        OnStomp::Components::Frame.new('SEND', {:transaction => 't-1234'}, 'message 3'),
      ]
    }
    
    def receipt_for frame
      raise "frame does not have a receipt header" unless frame.header?(:receipt)
      OnStomp::Components::Frame.new 'RECEIPT', :'receipt-id' => frame[:receipt]
    end
    
    describe "basic replaying" do
      before(:each) do
        buffer
      end
      ['ACK', 'NACK'].each do |command|
        it "should not replay #{command} frames" do
          frame = OnStomp::Components::Frame.new command
          active_client.trigger_before_transmitting frame
          active_client.should_not_receive(:transmit)
          failover.trigger_failover_event :connected, clients.first
        end
      end
      it "should attach a receipt header to frames lacking one" do
        frame = OnStomp::Components::Frame.new 'SEND',
          { :destination => '/queue/test' }, 'body of message'
        active_client.trigger_before_transmitting frame
        frame.header?(:receipt).should be_true
      end
      it "should not molest existing receipt headeres" do
        frame = OnStomp::Components::Frame.new 'SUBSCRIBE',
          { :destination => '/queue/test', :receipt => 'r-1234' }
        active_client.trigger_before_transmitting frame
        frame[:receipt].should == 'r-1234'
      end
      it "should replay SEND frames" do
        frame = OnStomp::Components::Frame.new 'SEND',
          { :destination => '/queue/test' }, 'body of message'
        active_client.trigger_before_transmitting frame
        active_client.should_receive(:transmit).with(an_onstomp_frame(
          'SEND', {:destination => '/queue/test'}, 'body of message'))
        failover.trigger_failover_event :connected, :on, clients.first
      end
      it "should debuffer non-transactional SEND frames" do
        frame = OnStomp::Components::Frame.new 'SEND',
          { :destination => '/queue/test' }, 'body of message'
        active_client.trigger_before_transmitting frame
        active_client.trigger_after_receiving receipt_for(frame)
        active_client.should_not_receive(:transmit)
        failover.trigger_failover_event :connected, :on, clients.first
      end
      it "should replay SUBSCRIBE frames, even receipted ones" do
        frame = OnStomp::Components::Frame.new 'SUBSCRIBE',
          { :destination => '/queue/test', :id => 's-1234' }
        active_client.trigger_before_transmitting frame
        active_client.trigger_after_receiving receipt_for(frame)
        active_client.should_receive(:transmit).with(an_onstomp_frame(
          'SUBSCRIBE', {:destination => '/queue/test', :id => 's-1234'}))
        failover.trigger_failover_event :connected, :on, clients.first
      end
      it "should debuffer SUBSCRIBE frames as soon as UNSUBSCRIBE is in the write buffer (does not need to be receipted)" do
        frame = OnStomp::Components::Frame.new 'SUBSCRIBE',
          { :destination => '/queue/test', :id => 's-1234' }
        active_client.trigger_before_transmitting frame
        active_client.trigger_after_transmitting frame
        frame = OnStomp::Components::Frame.new 'UNSUBSCRIBE', :id => 's-1234'
        active_client.trigger_before_transmitting frame
        active_client.should_not_receive :transmit
        failover.trigger_failover_event :connected, :on, clients.first
      end
      it "should not debuffer incomplete transactions" do
        replayed = []
        partial_transaction.each do |f|
          active_client.trigger_before_transmitting f
          active_client.trigger_after_transmitting f
        end
        active_client.stub(:transmit).and_return { |f| replayed << f; f }
        failover.trigger_failover_event :connected, :on, clients.first
        replayed.should == partial_transaction.reject { |f| ['ACK', 'NACK'].include? f.command }
      end
      ['ABORT', 'COMMIT'].each do |trans_fin|
        it "should not debuffer transactions when #{trans_fin} is only buffered" do
          fin_frame = OnStomp::Components::Frame.new trans_fin, {:transaction => 't-1234'}
          replayed = []
          partial_transaction.each do |f|
            active_client.trigger_before_transmitting f
            active_client.trigger_after_transmitting f
          end
          active_client.trigger_before_transmitting fin_frame
          active_client.stub(:transmit).and_return { |f| replayed << f; f }
          failover.trigger_failover_event :connected, :on, clients.first
          replayed.should ==
            (partial_transaction.reject { |f| ['ACK', 'NACK'].include? f.command } +
            [fin_frame])
        end
        it "should debuffer a transaction when #{trans_fin} has been written" do
          fin_frame = OnStomp::Components::Frame.new trans_fin, {:transaction => 't-1234'}
          replayed = []
          partial_transaction.each do |f|
            active_client.trigger_before_transmitting f
            active_client.trigger_after_transmitting f
          end
          active_client.trigger_before_transmitting fin_frame
          active_client.trigger_after_receiving receipt_for(fin_frame)
          active_client.stub(:transmit).and_return { |f| replayed << f; f }
          failover.trigger_failover_event :connected, :on, clients.first
          replayed.should be_empty
        end
      end
    end
    
    describe "replaying while you replay (Xzibit Approved)" do
      let(:frame_list) {
        [
          OnStomp::Components::Frame.new('SEND', {:destination => '/queue/test'}, 'message 1'),
          OnStomp::Components::Frame.new('SUBSCRIBE', :id => 's-1234', :destination => '/queue/test'),
          OnStomp::Components::Frame.new('BEGIN', :transaction => 't-1234'),
          OnStomp::Components::Frame.new('NACK', :'message-id' => 'm-99992'),
          OnStomp::Components::Frame.new('SEND', {:transaction => 't-1234'}, 'message 2'),
          OnStomp::Components::Frame.new('ACK', :'message-id' => 'm-99993'),
          OnStomp::Components::Frame.new('SEND', {:transaction => 't-1234'}, 'message 3'),
          OnStomp::Components::Frame.new('UNSUBSCRIBE', :id => 's-1234'),
          OnStomp::Components::Frame.new('SUBSCRIBE', :id => 's-5678', :destination => '/queue/test'),
          OnStomp::Components::Frame.new('ACK', {:transaction => 't-1234',
            :'message-id' => 'm-99991'}),
          OnStomp::Components::Frame.new('SEND', {:transaction => 't-1234'}, 'message 4'),
        ]
      }
      let(:expected_replay) {
        frame_list.reject do |f|
          ['ACK', 'NACK'].include?(f.command) || f[:id] == 's-1234'
        end
      }
      let(:client1_frames) { [] }
      let(:client3_frames) { [] }
      before(:each) do
        buffer
        frame_list.each do |f|
          active_client.trigger_before_transmitting f
        end
      end
      it "should replay properly if failover reconnects while replaying" do
        extra_frame = OnStomp::Components::Frame.new 'SEND',
          {:destination => '/queue/test'}, 'yet another freaking message'
        clients.last.stub(:transmit).and_return { |f| client3_frames << f; f }
        active_client.stub(:transmit).and_return do |f|
          client1_frames << f
          if f.command == 'BEGIN'
            # Add a fresh frame to the buffer
            active_client.trigger_before_transmitting extra_frame
            # Signal the a reconnect in the midst of replaying.
            failover.trigger_failover_event :connected, :on, clients.last
          end
          f
        end
        failover.trigger_failover_event :connected, :on, active_client
        client1_frames.should == expected_replay
        client3_frames.should == expected_replay + [extra_frame]
      end
    end
  end
end
