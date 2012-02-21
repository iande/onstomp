# -*- encoding: utf-8 -*-
require 'spec_helper'

module OnStomp::Components::Scopes
  describe HeaderScope do
    let(:client) {
      OnStomp::Client.new("stomp:///")
    }
    let(:headers) {
      { :header1 => 'value 1', 'header2' => 'value 2'}
    }
    let(:scope) {
      HeaderScope.new headers, client
    }
    
    let(:frame_method_interface) { scope }
    it_should_behave_like "frame method interfaces"

    it "sets up the connection attribute" do
      connection = stub('connection')
      client.should_receive(:connection).and_return(connection)
      scope.connection.should == connection
    end
    
    describe ".transmit" do
      it "should add all its headers to a frame, unless that header name is set" do
        client.stub(:transmit).and_return { |f,_| f }
        frame = scope.transmit OnStomp::Components::Frame.new('COMMAND', {:header2 => 'my value'})
        frame.should have_headers(:header1 => 'value 1', :header2 => 'my value')
      end
    end
  end
end
