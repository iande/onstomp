# -*- encoding: utf-8 -*-
require 'spec_helper'

module OnStomp::Connections::Serializers
  describe Stomp_1_0 do
    let(:serializer) { Stomp_1_0.new }
    describe "ancestors" do
      it "should be a kind of Stomp_1 serializer" do
        serializer.should be_a_kind_of(OnStomp::Connections::Serializers::Stomp_1)
      end
    end
    describe ".frame_to_string" do
      # So tests pass with Ruby 1.8.7, we need to get the headers in order
      let(:frame_without_body) {
        OnStomp::Components::Frame.new('COMMAND').tap do |f|
          f[:header1] = 'value 1'
          f[:header2] = 'value 2'
          f["header\nwith:specials"] = "value\nwith\nspecials"
        end
      }
      let(:frame_with_body) {
        OnStomp::Components::Frame.new('COMMAND',{},"body of message").tap do |f|
          f[:header1] = 'value 1'
          f[:header2] = 'value 2'
          f["header\nwith:specials"] = "value\nwith\nspecials"
        end
      }
      it "should convert a frame to a string with escaped headers" do
        serializer.frame_to_string(frame_without_body).should ==
          "COMMAND\nheader1:value 1\nheader2:value 2\nheaderwithspecials:valuewithspecials\n\n\000"
      end
      it "should generate a content-length" do
        serializer.frame_to_string(frame_with_body).should ==
          "COMMAND\nheader1:value 1\nheader2:value 2\nheaderwithspecials:valuewithspecials\ncontent-length:15\n\nbody of message\000"
      end
    end
    
    describe ".split_header" do
      it "should raise a malformed header error if the header line has no ':'" do
        lambda {
          serializer.split_header('header-name')
        }.should raise_error(OnStomp::MalformedHeaderError)
      end
      it "should return a header name / value pair" do
        serializer.split_header('header-name: some : value ').should ==
          ['header-name', ' some : value ']
      end
    end
  end
end
