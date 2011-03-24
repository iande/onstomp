# -*- encoding: utf-8 -*-
require 'spec_helper'

module OnStomp::Components
  describe URI do
    it "should make stomp:// strings parseable" do
      ::URI.parse("stomp:///").should be_a_kind_of(OnStomp::Components::URI::STOMP)
    end
    it "should make stomp+ssl:// strings parseable" do
      ::URI.parse("stomp+ssl:///").should be_a_kind_of(OnStomp::Components::URI::STOMP_SSL)
    end
    
    describe URI::STOMP do
      let(:uri) { ::URI.parse("stomp:///") }
      it "should have a default port of 61613" do
        uri.port.should == 61613
      end
      it "should have an onstomp_socket_type of :tcp" do
        uri.onstomp_socket_type.should == :tcp
      end
    end
    
    describe URI::STOMP_SSL do
      let(:uri) { ::URI.parse("stomp+ssl:///") }
      it "should have a default port of 61612" do
        uri.port.should == 61612
      end
      it "should have an onstomp_socket_type of :ssl" do
        uri.onstomp_socket_type.should == :ssl
      end
    end
  end
end
