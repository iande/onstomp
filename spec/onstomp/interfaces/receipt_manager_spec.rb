# -*- encoding: utf-8 -*-
require 'spec_helper'

module OnStomp::Interfaces
  describe ReceiptManager do
    let(:client) {
      mock('mock client').tap do |m|
        m.extend ClientEvents
        m.extend ReceiptManager
      end
    }
    let(:frame) {
      OnStomp::Components::Frame.new('COMMAND', :receipt => 'r-1234')
    }
    let(:receipt_frame) {
      OnStomp::Components::Frame.new('RECEIPT', :'receipt-id' => 'r-1234')
    }
    before(:each) do
      client.__send__(:configure_receipt_management)
    end
    after(:each) do
      client.__send__(:clear_receipts)
    end
        
    describe "adding receipt callbacks" do
      it "should add a callback and invoke it upon receiving its RECEIPT" do
        triggered = false
        client.__send__ :add_receipt, frame, lambda { |r| triggered = true }
        client.trigger_after_receiving receipt_frame
        triggered.should be_true
      end
      it "should create a receipt header if one does not exist" do
        frame.headers.delete :receipt
        triggered = false
        client.__send__ :add_receipt, frame, lambda { |r| triggered = true }
        frame[:receipt].should_not be_nil
        frame[:receipt].should_not be_empty
        receipt_frame[:'receipt-id'] = frame[:receipt]
        client.trigger_after_receiving receipt_frame
        triggered.should be_true
      end
    end
    
    describe "receipted DISCONNECT" do
      it "should close the client upon receiving a RECEIPT for a DISCONNECT" do
        frame.command = 'DISCONNECT'
        client.trigger_before_transmitting frame
        client.should_receive(:close)
        client.trigger_after_receiving receipt_frame
      end
    end
  end
end
