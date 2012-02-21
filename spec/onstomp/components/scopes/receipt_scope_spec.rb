# -*- encoding: utf-8 -*-
require 'spec_helper'

module OnStomp::Components::Scopes
  describe ReceiptScope do
    let(:client) {
      OnStomp::Client.new("stomp:///")
    }
    let(:receipt_back) {
      lambda { |r| true }
    }
    let(:scope) {
      ReceiptScope.new receipt_back, client
    }
    
    let(:frame_method_interface) { scope }
    it_should_behave_like "frame method interfaces"

    it "sets up the connection attribute" do
      connection = stub('connection')
      client.should_receive(:connection).and_return(connection)
      scope.connection.should == connection
    end
    
    describe ".transmit" do
      it "should add its receipt callback to frames transmitted without one" do
        frame = OnStomp::Components::Frame.new('COMMAND', {:header2 => 'my value'})
        client.should_receive(:transmit).with(frame, { :receipt => receipt_back })
        scope.transmit frame
      end
      it "should not add its receipt callback if one was already present" do
        alt_receipt_back = lambda { |r| false }
        frame = OnStomp::Components::Frame.new('COMMAND', {:header2 => 'my value'})
        client.should_receive(:transmit).with(frame, { :receipt => alt_receipt_back })
        scope.transmit frame, :receipt => alt_receipt_back
      end
    end
  end
end
